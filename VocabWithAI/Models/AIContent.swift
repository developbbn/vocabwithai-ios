//
//  AIContent.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  Gemini가 뱉는 ===CONTENT=== 블록의 구조화된 모델.
//  WordDetailView에서 섹션별로 렌더링하기 위해 사용.
//

import Foundation

// MARK: - Root

/// AI가 생성한 단어 학습 콘텐츠의 루트.
/// `===CONTENT===` 뒤쪽 JSON 문자열을 디코드한 결과.
struct AIContent: Codable, Equatable {

    /// 단어 전체의 핵심 한 줄 요약.
    /// 각 한자 의미가 합쳐져 이 단어의 뜻이 어떻게 나오는지.
    /// 구 데이터 호환 위해 optional.
    let summary: String?

    /// 한자 나노 분해 (Section 01). 단어에 한자가 없으면 빈 배열.
    let kanjiBreakdowns: [KanjiBreakdown]

    /// 관련 단어 그룹 (Section 02). 각 그룹은 출발 한자별.
    let relatedWords: [RelatedWordGroup]

    /// 실전 예문 (Section 03). 보통 3개.
    let examples: [Example]
}

// MARK: - Kanji Breakdown (Section 01)

struct KanjiBreakdown: Codable, Equatable, Identifiable {

    /// 한자 1글자. `id` 대용으로도 쓰임.
    let kanji: String

    /// 한국어 훈·뜻. 예: "날랠 용 / 용감할 용"
    let meaning: String

    /// 음독 + 로마자. 예: "ユウ (YUU)"
    let onyomi: String

    /// 훈독 + 로마자 + 의미. 훈독이 없으면 빈 문자열일 수 있음.
    /// 예: "いさ-む (isa-mu) — 용기를 내다, 기운을 내다"
    let kunyomi: String

    /// 부수 한자 + 이름. 예: "力 (힘 력)"
    let radical: String

    /// 모양 분해 — 구성 요소 카드들. 1~4개.
    let components: [KanjiComponent]

    /// 진짜 어원. FACT 박스에 렌더.
    let fact: String

    /// 뇌피셜 스토리. MSG 박스에 렌더.
    let msg: String

    /// Identifiable — 한자 자체가 유니크 키.
    var id: String { kanji }
}

/// 한자의 구성 요소 카드 (모양 분해).
struct KanjiComponent: Codable, Equatable, Identifiable {

    /// 구성 요소 한자 1글자. 예: "甬"
    let char: String

    /// 구성 요소의 훈·뜻. 예: "솟아오를 용"
    let meaning: String

    /// 해당 요소가 가지는 의미를 한 문장으로. 예: "무언가가 솟아오르거나 뚫고 나가는 모양"
    let description: String

    /// Identifiable — 구성 요소 char + meaning 조합으로 유니크.
    /// (한 한자 안에서 동일 char 중복 거의 없음)
    var id: String { "\(char)-\(meaning)" }
}

// MARK: - Related Words (Section 02)

/// 특정 한자에서 뻗어난 관련 단어 그룹.
struct RelatedWordGroup: Codable, Equatable, Identifiable {

    /// 파생의 출발점이 된 한자 1글자. 예: "勇"
    let sourceKanji: String

    /// 이 한자에서 파생된 단어들.
    let words: [RelatedWord]

    var id: String { sourceKanji }
}

struct RelatedWord: Codable, Equatable, Identifiable {

    /// 단어 한자 표기. 예: "勇者"
    let kanji: String

    /// 히라가나 읽기. 예: "ゆうしゃ"
    let reading: String

    /// 한국어 뜻. 예: "용사"
    let meaning: String

    /// 짧은 실전 예문 일본어 원문.
    let exampleJP: String

    /// 예문 한국어 번역.
    let exampleKR: String

    var id: String { kanji }
}

// MARK: - Example Sentences (Section 03)

struct Example: Codable, Equatable, Identifiable {

    /// 일본어 원문 (한자 포함).
    let jp: String

    /// 전체 문장의 히라가나 읽기 (어절 단위 공백).
    let furigana: String

    /// 자연스러운 한국어 번역.
    let kr: String

    /// 꿀팁 이모지 1개.
    let tipEmoji: String

    /// 실전 활용 꿀팁 한 문장.
    let tip: String

    /// Identifiable — jp 문장 자체가 유니크.
    var id: String { jp }
}

// MARK: - Decoder

extension AIContent {

    /// `Word.aiContent` (String?) 에 저장된 JSON 문자열을 `AIContent`로 디코드.
    /// - 디코드 성공 → AIContent 반환
    /// - 실패 (빈 문자열, 구 마크다운 포맷, 포맷 깨짐 등) → nil 반환
    ///
    /// WordDetailView에서 `if let content = AIContent.decode(from: word.aiContent)`
    /// 패턴으로 쓰고, nil이면 기존 MarkdownContentView fallback.
    static func decode(from jsonString: String?) -> AIContent? {
        guard let jsonString = jsonString, !jsonString.isEmpty else { return nil }

        // 혹시 모를 코드펜스 제거 (```json ... ```)
        let cleaned = stripCodeFence(jsonString)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // JSON 본문만 추출 (앞뒤 혹시 섞인 텍스트 방어)
        guard let jsonBody = extractJSONBody(cleaned),
              let data = jsonBody.data(using: .utf8) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(AIContent.self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ AIContent 디코드 실패: \(error)")
            #endif
            return nil
        }
    }

    /// 첫 `{` ~ 마지막 `}` 구간 추출.
    /// Gemini가 앞뒤에 공백/설명 섞을 때 대비.
    private static func extractJSONBody(_ text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else {
            return nil
        }
        return String(text[start...end])
    }

    /// ```json ... ``` 또는 ``` ... ``` 코드펜스 제거.
    private static func stripCodeFence(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```json") { s = String(s.dropFirst(7)) }
        else if s.hasPrefix("```") { s = String(s.dropFirst(3)) }
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
        return s
    }
}
