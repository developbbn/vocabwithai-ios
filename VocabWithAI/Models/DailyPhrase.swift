//
//  DailyPhrase.swift
//  VocabApp
//
//  Created on 2026-02-04
//

import Foundation

/// 오늘의 표현 데이터 모델.
/// Gemini API로부터 받아온 일본어 문법/표현 1개를 나타낸다.
/// - Identifiable: ForEach, List 등에서 id로 구분
/// - Codable: UserDefaults 저장/불러오기 (북마크 영속화)
/// - Hashable: NavigationLink(value:) 사용 시 필요
struct DailyPhrase: Identifiable, Codable, Hashable {

    /// 표현 고유 식별자. 북마크 추가/제거 시 id로 매칭
    let id: UUID

    /// 표현이 생성된 날짜. dateString 계산 프로퍼티에서 포맷팅에 사용
    let date: Date

    /// 핵심 문법/접속어 자체 (예: ~くせに, ~っぱなし)
    let japanese: String

    /// japanese의 히라가나 읽기 (예: くせに)
    let reading: String

    /// 한국어 뜻 (예: ~인 주제에, ~면서도)
    let meaning: String

    /// 해당 문법이 실제로 사용된 전체 예문
    let exampleSentence: String

    /// exampleSentence 전체의 히라가나 읽기. nil: 구버전 데이터
    let exampleFurigana: String?

    /// exampleSentence의 한국어 번역. nil: 구버전 데이터
    let exampleKorean: String?

    /// 1~2문장으로 요약한 사용 상황 설명
    let contextUsage: String

    /// Gemini가 생성한 마크다운 형식의 상세 설명
    let aiInsight: String?

    /// 북마크 여부. toggle 시 UserDefaults에 저장/제거
    var isBookmarked: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        japanese: String,
        reading: String,
        meaning: String,
        exampleSentence: String = "",
        exampleFurigana: String? = nil,
        exampleKorean: String? = nil,
        contextUsage: String,
        aiInsight: String? = nil,
        isBookmarked: Bool = false
    ) {
        self.id = id
        self.date = date
        self.japanese = japanese
        self.reading = reading
        self.meaning = meaning
        self.exampleSentence = exampleSentence
        self.exampleFurigana = exampleFurigana
        self.exampleKorean = exampleKorean
        self.contextUsage = contextUsage
        self.aiInsight = aiInsight
        self.isBookmarked = isBookmarked
    }
}

// MARK: - Helper
extension DailyPhrase {

    /// date를 한국어 형식으로 포맷팅한 문자열 (예: "4월 6일 목요일")
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }
}
