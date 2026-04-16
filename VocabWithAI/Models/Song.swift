//
//  Song.swift
//  VocabWithAI
//
//  Created on 2026-04-13
//

import Foundation

// MARK: - Song

/// 노래 1곡 데이터 모델.
/// songs.json에서 디코딩되어 SongRepository에 저장된다.
struct Song: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    let thumbnailURL: String
    let youtubeURL: String?     // 선택 필드 (있으면 저장, 없어도 무방)
    let youtubeID: String
    let jlptLevel: String
    let isRecommended: Bool
    let cards: [LyricCard]
}

// MARK: - HighlightWord

/// 카드 내 핵심 단어 1개. 단어 자체 + 읽기 + 뜻을 모두 포함한다.
struct HighlightWord: Codable, Hashable {
    let word: String
    let reading: String
    let meaning: String
    let type: String  // "word" → 단어 탭, "phrase" → 표현 탭
}

// MARK: - LyricCard

/// 특정 재생 시점에 슬라이드되는 학습 카드.
/// timestamp(초)에 도달하면 자동으로 해당 카드가 표시된다.
struct LyricCard: Identifiable, Codable, Hashable {
    let id: String
    let timestamp: Double        // 카드가 등장하는 재생 시각 (초 단위)
    let japanese: String         // 일본어 가사 (예: "明日の勇気をくれるから")
    let reading: String          // 히라가나 읽기
    let meaning: String          // 한국어 번역
    let highlightWords: [HighlightWord]  // 핵심 단어 목록 (word + reading + meaning)
}
