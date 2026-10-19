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
    }

    // MARK: - Public: 단어 삭제
    func deleteWord(_ word: Word) {
        repository.deleteWord(word)
    }

    func deleteWords(at offsets: IndexSet) {
        repository.deleteWords(at: offsets)
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
