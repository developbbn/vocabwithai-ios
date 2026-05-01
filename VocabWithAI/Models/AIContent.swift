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

struct AIContent: Codable, Equatable {
    let summary: String?
    let kanjiBreakdowns: [KanjiBreakdown]
    let relatedWords: [RelatedWordGroup]
    let examples: [Example]
}

// MARK: - Kanji Breakdown

struct KanjiBreakdown: Codable, Equatable, Identifiable {
    let kanji: String
    let meaning: String
    let onyomi: String
    let kunyomi: String
    let radical: String
    let components: [KanjiComponent]
    let fact: String
    let msg: String

    var id: String { kanji }
}

struct KanjiComponent: Codable, Equatable, Identifiable {
    let char: String
    let meaning: String
    let description: String

    var id: String { "\(char)-\(meaning)" }
}

// MARK: - Related Words

struct RelatedWordGroup: Codable, Equatable, Identifiable {
    let sourceKanji: String
    let words: [RelatedWord]

    var id: String { sourceKanji }
}

struct RelatedWord: Codable, Equatable, Identifiable {
    let kanji: String
    let reading: String
    let meaning: String
    let exampleJP: String
    let exampleKR: String

    var id: String { kanji }
}

// MARK: - Example Sentences

struct Example: Codable, Equatable, Identifiable {
    let jp: String
    let furigana: String
    let kr: String
    let tipEmoji: String
    let tip: String

    var id: String { jp }
}

// MARK: - Decoder

extension AIContent {

    /// Gemini 응답 JSON 문자열을 AIContent로 디코드.
    /// 실패 시 nil. GeminiService에서만 호출.
    static func decode(from jsonString: String?) -> AIContent? {
        guard let jsonString = jsonString, !jsonString.isEmpty else { return nil }

        let cleaned = stripCodeFence(jsonString)
            .trimmingCharacters(in: .whitespacesAndNewlines)

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

    private static func extractJSONBody(_ text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else {
            return nil
        }
        return String(text[start...end])
    }

    private static func stripCodeFence(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```json") { s = String(s.dropFirst(7)) }
        else if s.hasPrefix("```") { s = String(s.dropFirst(3)) }
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
        return s
    }
}
