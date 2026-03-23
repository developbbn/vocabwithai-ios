//
//  WordDetailViewModel.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import Foundation
import Combine

class WordDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var word: Word
    
    // MARK: - Computed Properties
    var synonyms: [String] {
        // 나중에 API나 데이터베이스에서 가져올 수 있음
        // 현재는 더미 데이터
        return ["Flexible", "Durable", "Tough"]
    }
    
    var antonyms: [String] {
        // 나중에 구현
        return []
    }
    
    // MARK: - Initialization
    init(word: Word) {
        self.word = word
    }
    
    // MARK: - Actions
    func playPronunciation() {
        // TTS 기능 - 나중에 구현
        print("Playing pronunciation for: \(word.word)")
    }
    
    func toggleBookmark() {
        // 북마크 기능 - 나중에 구현
    }
}
