//
//  DailyPhrase.swift
//  VocabApp
//
//  Created on 2026-02-04
//

import Foundation

struct DailyPhrase: Identifiable, Codable {
    let id: UUID
    let date: Date                    // 생성 날짜
    let japanese: String              // 일본어 표현 (お疲れ様でした)
    let reading: String               // 읽기 (おつかれさまでした)
    let meaning: String               // 한국어 뜻 (수고하셨습니다)
    let contextUsage: String          // 사용 상황 설명
    let aiInsight: String?            // AI 추가 설명 (전체 텍스트)
    var isBookmarked: Bool            // 북마크 여부
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        japanese: String,
        reading: String,
        meaning: String,
        contextUsage: String,
        aiInsight: String? = nil,
        isBookmarked: Bool = false
    ) {
        self.id = id
        self.date = date
        self.japanese = japanese
        self.reading = reading
        self.meaning = meaning
        self.contextUsage = contextUsage
        self.aiInsight = aiInsight
        self.isBookmarked = isBookmarked
    }
}

// MARK: - Helper
extension DailyPhrase {
    // 오늘 날짜 표시용
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 목요일"
        return formatter.string(from: date)
    }
}
