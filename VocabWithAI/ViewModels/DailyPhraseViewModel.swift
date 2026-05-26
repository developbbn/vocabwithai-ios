//
//  DailyPhraseViewModel.swift
//  VocabApp
//
//  Created on 2026-02-04
//  Updated on 2026-05-12 — UserDefaults → Firestore 마이그레이션
//                          + 외부 호출용 public saveBookmark/removeBookmark 노출
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// 오늘의 표현 화면(DailyPhraseView)의 상태와 비즈니스 로직.
/// 북마크는 `users/{uid}/bookmarkedPhrases/{phraseId}` Firestore 컬렉션에 저장.
/// Firestore Security Rules 가 사용자 격리를 자동으로 처리.
@MainActor
class DailyPhraseViewModel: ObservableObject {

    // MARK: - Singleton
    static let shared = DailyPhraseViewModel()

    // MARK: - Published Properties

    /// 현재 화면에 표시 중인 오늘의 표현 (Gemini 가 매일 생성, 메모리 보관).
    @Published var currentPhrase: DailyPhrase?

    /// Firestore 에서 동기화된 북마크 목록. UI 가 직접 구독해서 사용.
    @Published private(set) var bookmarkedPhrases: [DailyPhrase] = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let db = Firestore.firestore()
    private var bookmarksListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    /// 현재 로그인 사용자의 북마크 컬렉션 참조. 미로그인 시 nil.
    private var bookmarksCollection: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).collection("bookmarkedPhrases")
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Lifecycle (AuthManager 가 호출)

    /// 로그인 직후 호출. 북마크 실시간 동기화 시작.
    func startListening() {
        guard let collection = bookmarksCollection else {
            print("⚠️ DailyPhraseViewModel.startListening: 미로그인 상태")
            return
        }

        // 기존 리스너 정리
        stopBookmarksListener()

        bookmarksListener = collection
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("🔴 북마크 리스너 에러: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.bookmarkedPhrases = []
                    return
                }

                let decoded: [DailyPhrase] = documents.compactMap { doc in
                    try? doc.data(as: DailyPhrase.self)
                }

                self.bookmarkedPhrases = decoded

                // 현재 화면의 표현이 북마크 상태와 다르면 동기화
                if let current = self.currentPhrase {
                    let isBookmarked = decoded.contains { $0.id == current.id }
                    if current.isBookmarked != isBookmarked {
                        self.currentPhrase?.isBookmarked = isBookmarked
                    }
                }

                print("📡 북마크 동기화: \(decoded.count)개")
            }
    }

    /// 세션 종료 — 리스너 + 메모리 + 진행 중 비동기 콜백 모두 정리.
    /// signOut 시 호출. Firestore 데이터는 유지 → 재로그인 시 listener 가 자동 복원.
    func clearSession() {
        stopBookmarksListener()
        currentPhrase = nil
        bookmarkedPhrases = []
        errorMessage = nil
        cancellables.removeAll()
        print("🔌 DailyPhraseViewModel 세션 종료")
    }

    /// 메모리 + Firestore 북마크 컬렉션까지 모두 삭제.
    /// 테스트용 휴지통 버튼 / 계정 삭제 직전에 호출.
    func resetData() {
        guard let collection = bookmarksCollection else {
            clearSession()
            return
        }

        Task {
            do {
                let snapshot = try await collection.getDocuments()
                guard !snapshot.documents.isEmpty else {
                    await MainActor.run { self.clearSession() }
                    return
                }

                let batch = db.batch()
                snapshot.documents.forEach { batch.deleteDocument($0.reference) }
                try await batch.commit()
                print("🗑️ Firestore 북마크 \(snapshot.documents.count)개 일괄 삭제")

                await MainActor.run { self.clearSession() }
            } catch {
                print("🔴 북마크 일괄 삭제 실패: \(error.localizedDescription)")
                await MainActor.run { self.clearSession() }
            }
        }
    }

    private func stopBookmarksListener() {
        bookmarksListener?.remove()
        bookmarksListener = nil
    }

    // MARK: - Today's Phrase

    /// Gemini API를 호출해 새로운 오늘의 표현을 가져온다.
    func generateTodayPhrase() {
        isLoading = true
        errorMessage = nil

        print("🔵 오늘의 표현 생성 시작")

        GeminiService.shared.generateDailyPhrase()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false

                if case .failure(let error) = completion {
                    print("🔴 오늘의 표현 에러: \(error.localizedDescription)")
                    self?.errorMessage = "표현을 불러오는데 실패했습니다."
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                print("🟢 오늘의 표현 성공!")

                let phrase = DailyPhrase(
                    japanese: response.japanese,
                    reading: response.reading,
                    meaning: response.meaning,
                    exampleSentence: response.exampleSentence,
                    exampleFurigana: response.exampleFurigana,
                    exampleKorean: response.exampleKorean,
                    contextUsage: response.contextUsage,
                    aiInsight: response.aiInsight,
                    isBookmarked: false
                )

                self.currentPhrase = phrase
                self.isLoading = false
            }
            .store(in: &cancellables)
    }

    // MARK: - Bookmark (Public API)

    /// **외부 호출용 — 임의의 DailyPhrase 를 북마크에 추가.**
    /// SongPlayerView 같은 곳에서 currentPhrase 와 무관한 phrase 를 저장할 때 사용.
    /// 이미 같은 ID 가 있으면 덮어씀.
    func saveBookmark(_ phrase: DailyPhrase) {
        guard let collection = bookmarksCollection else {
            print("⚠️ saveBookmark: 미로그인 상태")
            return
        }

        var toSave = phrase
        toSave.isBookmarked = true

        let docId = phrase.id.uuidString

        Task {
            do {
                try collection.document(docId).setData(from: toSave)
                print("⭐️ 북마크 추가 (Firestore): \(phrase.japanese)")
            } catch {
                print("🔴 북마크 추가 실패: \(error.localizedDescription)")
                ToastManager.shared.show("저장에 실패했어요")
            }
        }
    }

    /// **외부 호출용 — 임의의 DailyPhrase 를 북마크에서 제거.**
    /// 북마크 목록 화면의 스와이프 삭제 등에서 사용.
    func removeBookmark(_ phrase: DailyPhrase) {
        guard let collection = bookmarksCollection else {
            print("⚠️ removeBookmark: 미로그인 상태")
            return
        }

        let docId = phrase.id.uuidString

        Task {
            do {
                try await collection.document(docId).delete()
                print("❌ 북마크 제거 (Firestore): \(phrase.japanese)")
            } catch {
                print("🔴 북마크 제거 실패: \(error.localizedDescription)")
                ToastManager.shared.show("삭제에 실패했어요")
            }
        }
    }

    /// 현재 화면의 표현(currentPhrase) 의 북마크 상태를 토글.
    /// UI 즉시 반응(낙관적 업데이트) + 실패 시 자동 revert.
    func toggleBookmark() {
        guard var phrase = currentPhrase else { return }
        guard let collection = bookmarksCollection else {
            print("⚠️ toggleBookmark: 미로그인 상태")
            return
        }

        let willBookmark = !phrase.isBookmarked

        // 1. 낙관적 UI 업데이트
        phrase.isBookmarked = willBookmark
        currentPhrase = phrase

        // 2. Firestore 반영
        let docId = phrase.id.uuidString

        Task {
            do {
                if willBookmark {
                    var toSave = phrase
                    toSave.isBookmarked = true
                    try collection.document(docId).setData(from: toSave)
                    print("⭐️ 북마크 추가 (toggle): \(phrase.japanese)")
                } else {
                    try await collection.document(docId).delete()
                    print("❌ 북마크 제거 (toggle): \(phrase.japanese)")
                }
            } catch {
                // 3. 실패 시 UI revert
                print("🔴 북마크 토글 실패: \(error.localizedDescription)")
                await MainActor.run {
                    self.currentPhrase?.isBookmarked = !willBookmark
                }
            }
        }
    }

    // MARK: - Deprecated (backward compat)

    /// ⚠️ Deprecated. `DailyPhraseViewModel.shared.bookmarkedPhrases` 를 직접 구독하는 패턴으로 전환할 것.
    @available(*, deprecated, message: "Observe `DailyPhraseViewModel.shared.bookmarkedPhrases` instead.")
    static func loadBookmarkedPhrases() -> [DailyPhrase] {
        return shared.bookmarkedPhrases
    }
}
