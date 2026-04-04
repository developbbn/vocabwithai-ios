//
//  EditWordViewModel.swift
//  VocabWithAI
//
//  Created on 2026-03-30
//

import Foundation

class EditWordViewModel: ObservableObject {

    // MARK: - Published
    @Published var word: String
    @Published var meaning: String
    @Published var pronunciation: String
    @Published var memo: String

    private let originalWord: Word
    var originalId: UUID { originalWord.id }

    // MARK: - Init
    init(word: Word) {
        self.originalWord   = word
        self.word           = word.word
        self.meaning        = word.meaning
        self.pronunciation  = word.pronunciation
        self.memo           = word.memo
    }

    // MARK: - Validation
    var isSaveEnabled: Bool {
        !word.trimmingCharacters(in: .whitespaces).isEmpty &&
        !meaning.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Save
    func save() {
        let updated = Word(
            id:            originalWord.id,
            word:          word.trimmingCharacters(in: .whitespaces),
            meaning:       meaning.trimmingCharacters(in: .whitespaces),
            pronunciation: pronunciation.trimmingCharacters(in: .whitespaces),
            memo:          memo.trimmingCharacters(in: .whitespaces),
            createdAt:     originalWord.createdAt,
            aiContent:     originalWord.aiContent,
            quizData:      originalWord.quizData
        )
        WordRepository.shared.updateWord(updated)
    }
}
