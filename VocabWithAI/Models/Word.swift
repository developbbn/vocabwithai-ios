//
//  Word.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import Foundation

struct Word: Identifiable, Codable {
    let id: UUID
    var word: String
    var meaning: String
    var pronunciation: String
    var memo: String
    var createdAt: Date
    
    // AI 생성 콘텐츠 (마크다운 형식)
    var aiContent: String?

    // AI 생성 퀴즈 선지 데이터
    var quizData: QuizData?

    init(
        id: UUID = UUID(),
        word: String = "",
        meaning: String = "",
        pronunciation: String = "",
        memo: String = "",
        createdAt: Date = Date(),
        aiContent: String? = nil,
        quizData: QuizData? = nil
    ) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.pronunciation = pronunciation
        self.memo = memo
        self.createdAt = createdAt
        self.aiContent = aiContent
        self.quizData = quizData
    }
}
