//
//  SearchViewModel.swift
//  VocabWithAI
//
//  Created on 2026-03-30
//

import Foundation
import Combine

// MARK: - 검색 필터 탭
enum SearchFilter: CaseIterable {
    case all, word, phrase

    var label: String {
        switch self {
        case .all:    return "전체"
        case .word:   return "단어"
        case .phrase: return "표현"
        }
    }
}

// MARK: - 검색 결과 통합 타입
enum SearchResult: Identifiable {
    case word(Word)
    case phrase(DailyPhrase)

    var id: String {
        switch self {
        case .word(let w):   return "word-\(w.id)"
        case .phrase(let p): return "phrase-\(p.id)"
        }
    }
}

// MARK: - 최근 검색어
struct RecentSearch: Codable, Identifiable {
    let id: UUID
    let query: String
    let date: Date

    init(query: String) {
        self.id    = UUID()
        self.query = query
        self.date  = Date()
    }
}

// MARK: - SearchViewModel
@MainActor
class SearchViewModel: ObservableObject {

    // MARK: - Input
    @Published var searchText: String = ""
    @Published var selectedFilter: SearchFilter = .all

    // MARK: - Output
    @Published private(set) var recentSearches: [RecentSearch] = []
    @Published private(set) var trendingWords: [Word] = []
    @Published private var results: [SearchResult] = []

    // MARK: - Computed (필터 탭 전환 시 재검색 없이 즉시 반응)
    var filteredResults: [SearchResult] {
        switch selectedFilter {
        case .all:
            return results
        case .word:
            return results.filter {
                if case .word = $0 { return true }
                return false
            }
        case .phrase:
            return results.filter {
                if case .phrase = $0 { return true }
                return false
            }
        }
    }

    var isSearching: Bool { !searchText.isEmpty }
    var hasResults: Bool  { !filteredResults.isEmpty }

    // MARK: - Private
    private let recentSearchesKey = "search_recentSearches"
    private let maxRecentCount    = 10
    private var cancellables      = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        loadRecentSearches()
        loadTrendingWords()
        bindSearchText()
    }

    // MARK: - Combine 바인딩
    private func bindSearchText() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self else { return }
                if text.isEmpty {
                    self.results = []
                } else {
                    self.performSearch(text)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 검색 실행
    private func performSearch(_ query: String) {
        let lowercased = query.lowercased()

        // 단어 검색: word / pronunciation / meaning 모두 포함
        let wordResults: [SearchResult] = WordRepository.shared.words
            .filter {
                $0.word.lowercased().contains(lowercased) ||
                $0.pronunciation.lowercased().contains(lowercased) ||
                $0.meaning.lowercased().contains(lowercased)
            }
            .map { .word($0) }

        // 표현 검색: 북마크된 표현에서만 (japanese / meaning)
        let phraseResults: [SearchResult] = DailyPhraseViewModel.loadBookmarkedPhrases()
            .filter {
                $0.japanese.lowercased().contains(lowercased) ||
                $0.meaning.lowercased().contains(lowercased)
            }
            .map { .phrase($0) }

        results = wordResults + phraseResults
    }

    // MARK: - 검색 확정 (키보드 검색 버튼 누를 때)
    func commitSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        saveRecentSearch(query)
    }

    // MARK: - 결과 탭 시 해당 단어/표현을 최근 검색어로 저장
    func saveResultAsRecentSearch(_ text: String) {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        saveRecentSearch(query)
    }

    // MARK: - 최근 검색어
    private func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.query == query }       // 중복 제거
        searches.insert(RecentSearch(query: query), at: 0)
        if searches.count > maxRecentCount {
            searches = Array(searches.prefix(maxRecentCount))
        }
        recentSearches = searches
        persist(searches)
    }

    func removeRecentSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.id == search.id }
        persist(recentSearches)
    }

    func clearAllRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }

    func selectRecentSearch(_ query: String) {
        searchText = query
    }

    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) else { return }
        recentSearches = decoded
    }

    private func persist(_ searches: [RecentSearch]) {
        if let encoded = try? JSONEncoder().encode(searches) {
            UserDefaults.standard.set(encoded, forKey: recentSearchesKey)
        }
    }

    // MARK: - 오늘의 인기 단어 (WordRepository에서 랜덤 3개)
    private func loadTrendingWords() {
        trendingWords = Array(WordRepository.shared.words.shuffled().prefix(3))
    }
}
