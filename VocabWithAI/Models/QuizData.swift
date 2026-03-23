//
//  QuizData.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import Foundation

/// 단어 등록 시 AI가 백그라운드로 생성해두는 퀴즈 선지 데이터
struct QuizData: Codable {
    /// 히라가나 맞추기 선지 4개 (정답 포함)
    /// 예: ["こうぎ", "こぎ", "きょうぎ", "こうき"]
    let hiraganaChoices: [String]

    /// 한자 맞추기 선지 4개 (정답 포함)
    /// 예: ["講義", "企業", "工事", "講師"]
    let kanjiChoices: [String]
}
