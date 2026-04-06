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
    /// 전체 문장이 아닌 문법 항목만 들어감
    let japanese: String

    /// japanese의 히라가나 읽기 (예: くせに)
    let reading: String

    /// 한국어 뜻 (예: ~인 주제에, ~면서도)
    let meaning: String

    /// 해당 문법이 실제로 사용된 전체 예문 (예: 彼は新人にしては、仕事が早い。)
    /// GeminiService 프롬프트의 exampleSentence 키에 대응
    let exampleSentence: String

    /// 1~2문장으로 요약한 사용 상황 설명
    let contextUsage: String

    /// Gemini가 생성한 마크다운 형식의 상세 설명
    /// - 접속 방법, 실전 예문, JLPT 출제 포인트 등 포함
    /// - nil: 아직 AI 응답을 받지 못한 경우
    let aiInsight: String?

    /// 북마크 여부. toggle 시 UserDefaults에 저장/제거
    var isBookmarked: Bool

    /// 기본값을 활용한 편의 이니셜라이저.
    /// - id: 생략 시 새 UUID 자동 생성
    /// - date: 생략 시 현재 시각
    /// - exampleSentence: 생략 시 빈 문자열 (구버전 데이터 디코딩 호환)
    /// - aiInsight: 생략 시 nil
    /// - isBookmarked: 생략 시 false
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        japanese: String,
        reading: String,
        meaning: String,
        exampleSentence: String = "",
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
        self.contextUsage = contextUsage
        self.aiInsight = aiInsight
        self.isBookmarked = isBookmarked
    }
}

// MARK: - Helper
extension DailyPhrase {

    /// date를 한국어 형식으로 포맷팅한 문자열 (예: "4월 6일 목요일")
    /// DailyPhraseView, PhraseDetailView의 dateHeader에서 사용
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }
}
