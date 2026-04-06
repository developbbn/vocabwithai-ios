//
//  DailyPhraseViewModel.swift
//  VocabApp
//
//  Created on 2026-02-04
//

import Foundation
import Combine

/// 오늘의 표현 화면(DailyPhraseView)의 상태와 비즈니스 로직을 담당하는 ViewModel.
/// - 싱글톤: 앱 전체에서 하나의 인스턴스를 공유. 탭 전환 시에도 상태 유지
/// - ObservableObject: @Published 프로퍼티 변경 시 뷰 자동 업데이트
class DailyPhraseViewModel: ObservableObject {

    // MARK: - Singleton
    /// 앱 전체에서 공유하는 단일 인스턴스.
    /// HomeView, DailyPhraseView 등 여러 뷰에서 같은 데이터를 참조
    static let shared = DailyPhraseViewModel()

    // MARK: - Published Properties

    /// 현재 표시 중인 오늘의 표현.
    /// nil: 아직 로드 안 됨 또는 로딩 중
    /// DailyPhraseView에서 이 값을 기반으로 UI 분기
    @Published var currentPhrase: DailyPhrase?

    /// API 요청 중 여부. true일 때 로딩 인디케이터 표시
    @Published var isLoading: Bool = false

    /// 에러 발생 시 사용자에게 보여줄 메시지.
    /// nil: 정상 상태
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// Combine 구독 생명주기 관리.
    /// ViewModel이 해제되면 자동으로 구독도 취소됨
    private var cancellables = Set<AnyCancellable>()

    /// UserDefaults 북마크 저장 키
    private let storageKey = "bookmarkedPhrases"

    // MARK: - Initialization

    /// 외부에서 인스턴스 생성 금지. shared를 통해서만 접근 가능
    private init() {}

    // MARK: - Public Methods

    /// Gemini API를 호출해 새로운 오늘의 표현을 가져온다.
    /// - 호출 시 isLoading = true, errorMessage = nil로 초기화
    /// - 성공: currentPhrase 업데이트
    /// - 실패: errorMessage 설정
    func generateTodayPhrase() {
        isLoading = true
        errorMessage = nil

        print("🔵 오늘의 표현 생성 시작")

        GeminiService.shared.generateDailyPhrase()
            .receive(on: DispatchQueue.main) // UI 업데이트는 반드시 메인 스레드에서
            .sink { [weak self] completion in
                self?.isLoading = false

                if case .failure(let error) = completion {
                    print("🔴 오늘의 표현 에러: \(error.localizedDescription)")
                    self?.errorMessage = "표현을 불러오는데 실패했습니다."
                }
            } receiveValue: { [weak self] response in
                print("🟢 오늘의 표현 성공!")

                // DailyPhraseResponse(API 응답 모델) → DailyPhrase(앱 내부 모델) 변환
                // exampleSentence: 프롬프트에서 요청한 전체 예문 문장
                let phrase = DailyPhrase(
                    japanese: response.japanese,
                    reading: response.reading,
                    meaning: response.meaning,
                    exampleSentence: response.exampleSentence,
                    contextUsage: response.contextUsage,
                    aiInsight: response.aiInsight,
                    isBookmarked: false
                )

                self?.currentPhrase = phrase
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    /// 현재 표현의 북마크 상태를 토글하고 UserDefaults에 반영한다.
    /// - currentPhrase가 nil이면 아무 동작 안 함
    func toggleBookmark() {
        guard var phrase = currentPhrase else { return }

        phrase.isBookmarked.toggle()
        currentPhrase = phrase

        if phrase.isBookmarked {
            saveBookmark(phrase)
            print("⭐️ 북마크 추가: \(phrase.japanese)")
        } else {
            removeBookmark(phrase)
            print("❌ 북마크 제거: \(phrase.japanese)")
        }
    }

    /// 오늘의 표현 데이터를 전부 초기화한다.
    /// HomeView의 전체 리셋 버튼에서 호출
    func resetData() {
        currentPhrase = nil
        errorMessage = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ 오늘의 표현 초기화 완료")
    }

    // MARK: - Private Methods

    /// 표현을 UserDefaults 북마크 목록에 저장한다.
    /// - 같은 japanese 값이 이미 있으면 덮어쓰기 (중복 방지)
    private func saveBookmark(_ phrase: DailyPhrase) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.japanese == phrase.japanese }
        bookmarks.append(phrase)

        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// 표현을 UserDefaults 북마크 목록에서 제거한다.
    /// - id 기반으로 매칭하여 정확한 항목만 삭제
    private func removeBookmark(_ phrase: DailyPhrase) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.id == phrase.id }

        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// UserDefaults에서 북마크된 표현 목록을 불러온다.
    /// - 디코딩 실패 또는 데이터 없으면 빈 배열 반환
    private func loadBookmarks() -> [DailyPhrase] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let phrases = try? JSONDecoder().decode([DailyPhrase].self, from: data) else {
            return []
        }
        return phrases
    }

    // MARK: - Static Method

    /// 다른 ViewModel(LibraryViewModel 등)에서 북마크 목록에 접근할 때 사용하는 정적 메서드.
    /// 인스턴스 없이 직접 UserDefaults를 읽어 반환
    static func loadBookmarkedPhrases() -> [DailyPhrase] {
        guard let data = UserDefaults.standard.data(forKey: "bookmarkedPhrases"),
              let phrases = try? JSONDecoder().decode([DailyPhrase].self, from: data) else {
            return []
        }
        return phrases
    }
}
