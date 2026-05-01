//
//  Word.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import Foundation

struct Word: Identifiable, Codable {
    /// Firestore docID와 동일하게 사용되는 식별자.
    /// 클라이언트에서 `UUID().uuidString`으로 생성.
    var id: String
    var word: String
    var meaning: String
    var pronunciation: String
    var memo: String
    var createdAt: Date

    /// AI 생성 학습 콘텐츠 (구조화).
    /// 단어 등록 직후엔 nil이고, 백그라운드 AI 호출 완료 후 채워짐.
    var aiContent: AIContent?

    /// AI 생성 퀴즈 선지 데이터.
    var quizData: QuizData?

    init(
        id: String = UUID().uuidString,
        word: String = "",
        meaning: String = "",
        pronunciation: String = "",
        memo: String = "",
        createdAt: Date = Date(),
        aiContent: AIContent? = nil,
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
