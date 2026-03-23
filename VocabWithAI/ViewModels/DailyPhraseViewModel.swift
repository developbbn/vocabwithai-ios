//
//  DailyPhraseViewModel.swift
//  VocabApp
//
//  Created on 2026-02-04
//

import Foundation
import Combine

class DailyPhraseViewModel: ObservableObject {
    static let shared = DailyPhraseViewModel()  // ← 싱글톤
    
    // MARK: - Published Properties
    @Published var currentPhrase: DailyPhrase?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let storageKey = "bookmarkedPhrases"
    
    // MARK: - Initialization
    private init() {}  // ← private으로 변경 (외부 생성 금지)
    
    // MARK: - Public Methods
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
                
                // DailyPhraseResponse를 DailyPhrase로 변환
                let phrase = DailyPhrase(
                    japanese: response.japanese,
                    reading: response.reading,
                    meaning: response.meaning,
                    contextUsage: response.contextUsage,
                    aiInsight: response.aiInsight,
                    isBookmarked: false
                )
                
                self?.currentPhrase = phrase
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    func toggleBookmark() {
        guard var phrase = currentPhrase else { return }
        
        phrase.isBookmarked.toggle()
        currentPhrase = phrase
        
        if phrase.isBookmarked {
            // 북마크 추가
            saveBookmark(phrase)
            print("⭐️ 북마크 추가: \(phrase.japanese)")
        } else {
            // 북마크 제거
            removeBookmark(phrase)
            print("❌ 북마크 제거: \(phrase.japanese)")
        }
    }
    
    func resetData() {
        currentPhrase = nil
        errorMessage = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ 오늘의 표현 초기화 완료")
    }
    
    // MARK: - Private Methods (북마크 저장/로드)
    private func saveBookmark(_ phrase: DailyPhrase) {
        var bookmarks = loadBookmarks()
        
        // 중복 체크 (같은 일본어 표현이면 덮어쓰기)
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
    
    // MARK: - Static Method (다른 ViewModel에서 사용)
    static func loadBookmarkedPhrases() -> [DailyPhrase] {
        guard let data = UserDefaults.standard.data(forKey: "bookmarkedPhrases"),
              let phrases = try? JSONDecoder().decode([DailyPhrase].self, from: data) else {
            return []
        }
        return phrases
    }
}
