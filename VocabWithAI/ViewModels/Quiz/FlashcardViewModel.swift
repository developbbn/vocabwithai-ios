//
//  FlashcardViewModel.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import Foundation
import AVFoundation
import Combine

class FlashcardViewModel: ObservableObject {

    // MARK: - Published
    @Published var words: [Word] = []
    @Published var currentIndex: Int = 0
    @Published var isFlipped: Bool = false
    @Published var isFinished: Bool = false
    @Published var knewCount: Int = 0
    @Published var didntKnowCount: Int = 0

    // MARK: - Private
    private var unknownWords: [Word] = []
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Init
    init() {
        words = WordRepository.shared.words.shuffled()
    }

    // MARK: - Computed
    var currentWord: Word? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    // MARK: - Actions

    func answer(knew: Bool) {
        guard currentIndex < words.count else { return }

        DailyStatsManager.shared.incrementQuizCount()

        if knew {
            knewCount += 1
        } else {
            didntKnowCount += 1
            unknownWords.append(words[currentIndex])
        }

        isFlipped = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if self.currentIndex + 1 >= self.words.count {
                self.isFinished = true
            } else {
                self.currentIndex += 1
            }
        }
    }

    func speak() {
        guard let word = currentWord else { return }
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }

    func retryUnknown() {
        words = unknownWords.shuffled()
        reset()
    }

    func restart() {
        words = WordRepository.shared.words.shuffled()
        reset()
    }

    private func reset() {
        currentIndex = 0
        isFlipped = false
        isFinished = false
        knewCount = 0
        didntKnowCount = 0
        unknownWords = []
    }
}
