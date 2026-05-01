//
//  LibraryViewModel.swift
//  VocabWithAI
//
//  Created on 2026-02-03
//

import Foundation
import Combine

@MainActor
class LibraryViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var words: [Word] = []
    @Published var phrases: [DailyPhrase] = []
    @Published var selectedTab: LibraryTab = .word
    @Published var searchText: String = ""

    // MARK: - Tab Enum
    enum LibraryTab {
        case word
        case expression
    }

    // MARK: - Dependency
    private let repository: WordRepository

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(repository: WordRepository = .shared) {
        self.repository = repository
        setupBindings()
        loadPhrases()
    }

    // MARK: - Combine Bindings
    @MainActor
    private func setupBindings() {
        // WordRepository의 words를 직접 구독 → 항상 최신 상태 유지
        repository.$words
            .combineLatest($searchText)
            .map { words, searchText in
                let sorted = words.sorted { $0.createdAt > $1.createdAt }
                guard !searchText.isEmpty else { return sorted }
                return sorted.filter {
                    $0.word.localizedCaseInsensitiveContains(searchText) ||
                    $0.meaning.localizedCaseInsensitiveContains(searchText)
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$words)

        // 탭 변경 시 표현 탭이면 다시 로드
        $selectedTab
            .filter { $0 == .expression }
            .sink { [weak self] _ in self?.loadPhrases() }
            .store(in: &cancellables)

        // 검색어 변경 시 표현도 필터링
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadPhrases() }
            .store(in: &cancellables)
    }

    // MARK: - Public: 단어 삭제
    func deleteWord(_ word: Word) {
        repository.deleteWord(word)
    }

    func deleteWords(at offsets: IndexSet) {
        repository.deleteWords(at: offsets)
    }

    // MARK: - Public: 표현
    func loadPhrases() {
        let allPhrases = DailyPhraseViewModel.loadBookmarkedPhrases()
            .sorted { $0.date > $1.date }
        if searchText.isEmpty {
            phrases = allPhrases
        } else {
            phrases = allPhrases.filter {
                $0.japanese.localizedCaseInsensitiveContains(searchText) ||
                $0.reading.localizedCaseInsensitiveContains(searchText) ||
                $0.meaning.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    func deletePhrase(_ phrase: DailyPhrase) {
        phrases.removeAll { $0.id == phrase.id }
        savePhrases()
    }

    private func savePhrases() {
        if let encoded = try? JSONEncoder().encode(phrases) {
            UserDefaults.standard.set(encoded, forKey: "bookmarkedPhrases")
        }
    }
}
