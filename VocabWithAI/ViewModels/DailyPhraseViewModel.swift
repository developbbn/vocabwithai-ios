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
    static let shared = DailyPhraseViewModel()

    // MARK: - Published Properties

    @Published var currentPhrase: DailyPhrase?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let storageKey = "bookmarkedPhrases"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

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
                print("🟢 오늘의 표현 성공!")

                // DailyPhraseResponse(API 응답 모델) → DailyPhrase(앱 내부 모델) 변환
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

                self?.currentPhrase = phrase
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    /// 현재 표현의 북마크 상태를 토글하고 UserDefaults에 반영한다.
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
    func resetData() {
        currentPhrase = nil
        errorMessage = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ 오늘의 표현 초기화 완료")
    }

    // MARK: - Private Methods

    func saveBookmark(_ phrase: DailyPhrase) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.japanese == phrase.japanese }
        bookmarks.append(phrase)

        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func removeBookmark(_ phrase: DailyPhrase) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.id == phrase.id }

        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadBookmarks() -> [DailyPhrase] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let phrases = try? JSONDecoder().decode([DailyPhrase].self, from: data) else {
            return []
        }
        return phrases
    }

    // MARK: - Static Method

    static func loadBookmarkedPhrases() -> [DailyPhrase] {
        guard let data = UserDefaults.standard.data(forKey: "bookmarkedPhrases"),
              let phrases = try? JSONDecoder().decode([DailyPhrase].self, from: data) else {
            return []
        }
        return phrases
    }
}
