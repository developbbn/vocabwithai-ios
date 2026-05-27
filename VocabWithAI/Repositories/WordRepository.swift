//
//  WordRepository.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//  Refactored on 2026-04-27 — Firestore 전환
//  Updated on 2026-05-12 — 세션 격리 강화 (cancellables 정리)
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class WordRepository: ObservableObject {

    // MARK: - Singleton
    static let shared = WordRepository()
    private init() {}

    // MARK: - Published State
    @Published private(set) var words: [Word] = []
    @Published private(set) var loadingWordIds: Set<String> = []

    // MARK: - Private
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    /// 현재 로그인 사용자의 words 컬렉션 참조. 미로그인 시 nil.
    private var wordsCollection: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).collection("words")
    }

    // MARK: - Lifecycle (AuthManager가 호출)

    /// 로그인 직후 호출. 실시간 리스너 시작.
    func startListening() {
        guard let collection = wordsCollection else {
            print("⚠️ startListening: 미로그인 상태")
            return
        }

        // 기존 리스너 정리
        stopListening()

        listener = collection
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("🔴 Firestore 리스너 에러: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.words = []
                    return
                }

                let decoded: [Word] = documents.compactMap { doc in
                    try? doc.data(as: Word.self)
                }

                self.words = decoded
                print("📡 Firestore 동기화: \(decoded.count)개 단어")
            }
    }

    /// 로그아웃 시 호출. 리스너 정리 + 로컬 상태 초기화 + 진행 중인 비동기 콜백 차단.
    ///
    /// 마지막 `cancellables.removeAll()` 이 중요한 이유:
    /// - test00 이 단어 등록 → AI 생성 중 (네트워크 대기) → 즉시 로그아웃 → test01 로그인
    /// - 이때 cancellable 이 살아있으면 늦게 도착한 Gemini 응답이 `updateAIContent` 호출
    /// - `wordsCollection` 은 동적으로 currentUser 참조하므로 → test01 컬렉션에 쓰일 수 있음
    /// - 따라서 세션 종료 시 진행 중인 모든 작업을 명시적으로 취소해야 안전.
    func stopListening() {
        listener?.remove()
        listener = nil
        words = []
        loadingWordIds = []
        cancellables.removeAll()
        print("🔌 WordRepository 세션 종료: 리스너/캐시/콜백 모두 정리")
    }

    // MARK: - Public: 단어 등록
    func registerWord(word: String, meaning: String, pronunciation: String, memo: String) {
        guard let collection = wordsCollection else {
            print("⚠️ registerWord: 미로그인 상태")
            return
        }

        let newWord = Word(
            word: word,
            meaning: meaning,
            pronunciation: pronunciation,
            memo: memo,
            aiContent: nil
        )

        Task {
            do {
                try collection.document(newWord.id).setData(from: newWord)
                print("✅ 단어 저장 완료: \(word)")

                DailyStatsManager.shared.incrementWordCount()

                // 백그라운드 AI 생성
                generateAIContent(for: newWord)
            } catch {
                print("🔴 단어 저장 실패: \(error.localizedDescription)")
                ToastManager.shared.show("저장에 실패했어요")
            }
        }
    }

    // MARK: - Public: AI 콘텐츠 재생성
    func regenerateAIContent(for word: Word) {
        guard let collection = wordsCollection else { return }

        Task {
            do {
                try await collection.document(word.id).updateData([
                    "aiContent": NSNull(),
                    "quizData": NSNull()
                ])
                print("🔄 AI 재생성 시작: \(word.word)")

                var refreshed = word
                refreshed.aiContent = nil
                refreshed.quizData = nil
                generateAIContent(for: refreshed)
            } catch {
                print("🔴 재생성 초기화 실패: \(error.localizedDescription)")
                ToastManager.shared.show("재생성에 실패했어요")
            }
        }
    }

    // MARK: - Public: 단어 수정
    func updateWord(_ updated: Word) {
        guard let collection = wordsCollection else { return }
        guard let original = words.first(where: { $0.id == updated.id }) else { return }

        let wordChanged = original.word != updated.word

        var wordToSave = updated
        if wordChanged {
            wordToSave.aiContent = nil
            wordToSave.quizData = nil
        }

        Task {
            do {
                try collection.document(wordToSave.id).setData(from: wordToSave)
                print("✏️ 단어 수정 완료: \(updated.word)")

                if wordChanged {
                    generateAIContent(for: wordToSave)
                }
            } catch {
                print("🔴 단어 수정 실패: \(error.localizedDescription)")
                ToastManager.shared.show("수정에 실패했어요")
            }
        }
    }

    // MARK: - Public: 단어 삭제
    func deleteWord(_ word: Word) {
        guard let collection = wordsCollection else { return }

        Task {
            do {
                try await collection.document(word.id).delete()
                print("🗑️ 단어 삭제 완료: \(word.word)")
            } catch {
                print("🔴 단어 삭제 실패: \(error.localizedDescription)")
                ToastManager.shared.show("삭제에 실패했어요")
            }
        }
    }

    func deleteAllWords() {
        guard let collection = wordsCollection else { return }
        let ids = words.map { $0.id }

        Task {
            let batch = db.batch()
            for id in ids {
                batch.deleteDocument(collection.document(id))
            }
            do {
                try await batch.commit()
                print("🗑️ 전체 삭제 완료")
            } catch {
                print("🔴 전체 삭제 실패: \(error.localizedDescription)")
                ToastManager.shared.show("삭제에 실패했어요")
            }
        }
    }

    func deleteWords(at offsets: IndexSet) {
        let targets = offsets.map { words[$0] }
        for word in targets {
            deleteWord(word)
        }
    }

    // MARK: - Private: 백그라운드 AI 생성
    private func generateAIContent(for word: Word) {
        print("🔵 백그라운드 AI 생성 시작: \(word.word)")
        loadingWordIds.insert(word.id)

        GeminiService.shared.generateWordContent(for: word.word)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let error) = completion {
                    print("🔴 AI 에러 (\(word.word)): \(error.localizedDescription)")
                    if let gError = error as? GeminiError,
                       case .rateLimitExceeded = gError {
                        ToastManager.shared.show(gError.localizedDescription)
                    }
                }
                self.loadingWordIds.remove(word.id)
            } receiveValue: { [weak self] result in
                guard let self else { return }
                print("🟢 AI 성공: \(word.word) / quizData: \(result.quizData != nil ? "✅" : "❌")")
                self.updateAIContent(wordId: word.id, result: result)
                self.loadingWordIds.remove(word.id)
                ToastManager.shared.show("「\(word.word)」 AI 분석 완료! ✨")
            }
            .store(in: &cancellables)
    }

    // MARK: - Private: AI 결과 Firestore 업데이트
    private func updateAIContent(wordId: String, result: WordAIContent) {
        guard let collection = wordsCollection else { return }

        let aiContent = AIContent.decode(from: result.aiContent)

        Task {
            do {
                var updateData: [String: Any] = [:]

                if let aiContent = aiContent,
                   let encoded = try? Firestore.Encoder().encode(aiContent) {
                    updateData["aiContent"] = encoded
                }

                if let quizData = result.quizData,
                   let encoded = try? Firestore.Encoder().encode(quizData) {
                    updateData["quizData"] = encoded
                }

                guard !updateData.isEmpty else { return }

                try await collection.document(wordId).updateData(updateData)
                print("💾 AI 콘텐츠 Firestore 업데이트 완료")
            } catch {
                print("🔴 AI 콘텐츠 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
}
