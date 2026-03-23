//
//  GeminiService.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import Foundation
import Combine

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent"
    
    private init() {
        self.apiKey = "AIzaSyBgYrNzJFhUzaxS27v9nA5VomxpcClk6Kk"
    }
    
    // MARK: - Generate Word Content
    func generateWordContent(for word: String) -> AnyPublisher<WordAIContent, Error> {
        let prompt = """
        일본어 단어 "\(word)"에 대해 아래 형식을 반드시 지켜서 응답해주세요.
        설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.

        ===QUIZ===
        {"hiraganaChoices":["정답히라가나","오답1","오답2","오답3"],"kanjiChoices":["정답한자","오답1","오답2","오답3"]}
        ===CONTENT===
        (여기에 마크다운 학습 자료)

        [QUIZ 작성 규칙]
        - hiraganaChoices: 정확한 히라가나 읽기 1개 + 헷갈리기 쉬운 유사 발음 오답 3개. 정답을 첫 번째 원소로.
          예) 講義 → ["こうぎ","こぎ","きょうぎ","こうき"]
        - kanjiChoices: 이 단어의 한자 표기 1개 + 혼동하기 쉬운 한자 단어 오답 3개. 정답을 첫 번째 원소로.
          예) こうぎ → ["講義","講師","工事","企業"]
        - 히라가나/가타카나 단어라면 kanjiChoices도 히라가나/가타카나 선지로 구성할 것.
        - 4개의 선지는 반드시 모두 서로 다른 문자열이어야 함. 중복 절대 금지.
        - 정답과 오답 3개가 조금이라도 같으면 안 됨. 글자 하나라도 다른 완전히 다른 표현을 사용할 것.
        - JSON은 반드시 한 줄로 작성할 것. 줄바꿈 없이.

        [CONTENT 작성 규칙]
        한국인 학습자를 위한 마크다운 학습 자료. 이모지 적극 활용.
        ## 1. 한자 분석 (해당되는 경우)
        - 부수, 음독, 훈독 / 획수 및 구성 요소 / 어원 및 유래 / 암기 스토리
        ## 2. 관련 단어 (고구마 줄기)
        - 파생어나 관련 표현 4-5개 (읽기, 뜻, 예문 포함)
        ## 3. 뉘앙스 설명
        - 사용 상황 / 비슷한 단어와의 차이점
        ## 4. 실전 예문 (일본 생활 밀착형)
        - 편의점, 지하철, 식당, 회사 등 실제 상황 3가지
        - 각 예문: 일본어 원문 / 히라가나 읽기 / 한국어 번역 / 상황 설명(이모지)
        ## 5. 학습 팁
        - 암기 방법이나 주의사항
        """

        return Future<WordAIContent, Error> { promise in
            guard let url = URL(string: "\(self.baseURL)?key=\(self.apiKey)") else {
                promise(.failure(GeminiError.invalidURL)); return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let requestBody: [String: Any] = ["contents": [["parts": [["text": prompt]]]]]
            request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { promise(.failure(error)); return }
                guard let data = data else { promise(.failure(GeminiError.noData)); return }
                do {
                    let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
                        promise(.failure(GeminiError.invalidResponse)); return
                    }
                    print("📦 Raw Response: \(text)")
                    let result = self.parseWordAIContent(from: text)
                    print("✅ quizData: \(result.quizData != nil ? "파싱 성공" : "없음")")
                    promise(.success(result))
                } catch {
                    print("🔴 Decoding Error: \(error)")
                    if let err = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("❌ Error Response: \(err)")
                    }
                    promise(.failure(error))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Helper: Word AI Content 구분자 파싱
    private func parseWordAIContent(from text: String) -> WordAIContent {
        let quizMarker = "===QUIZ==="
        let contentMarker = "===CONTENT==="
        guard let quizRange = text.range(of: quizMarker),
              let contentRange = text.range(of: contentMarker) else {
            print("⚠️ 구분자 없음, 전체 텍스트를 aiContent로 저장")
            return WordAIContent(aiContent: text, quizData: nil)
        }
        let quizRaw = String(text[quizRange.upperBound..<contentRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let quizJsonStr = extractJSON(from: quizRaw)
        var quizData: QuizData? = nil
        if let jsonData = quizJsonStr.data(using: .utf8) {
            quizData = try? JSONDecoder().decode(QuizData.self, from: jsonData)
            if quizData == nil { print("⚠️ quizData JSON 파싱 실패: \(quizJsonStr)") }
        }
        let aiContent = String(text[contentRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return WordAIContent(aiContent: aiContent, quizData: quizData)
    }

    // MARK: - Generate Daily Phrase
    func generateDailyPhrase() -> AnyPublisher<DailyPhraseResponse, Error> {
        let prompt = """
        당신은 한국인 학습자를 위한 전문 일본어 강사이자 네이티브 스피커입니다.
        일본어 학습 앱의 "오늘의 표현" 기능에 제공할 표현 1개를 아래 형식을 반드시 지켜서 응답해주세요.
        설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.
        
        항상 랜덤으로 주세요!!

        ===PHRASE===
        {"japanese":"[한자/가나]","reading":"[히라가나]","meaning":"[한국어 뜻]","contextUsage":"[1~2문장 상황 설명]"}
        ===INSIGHT===
        (여기에 마크다운 상세 설명)

        [표현 선정 기준] 아래 중 하나를 무작위로 선택:
        1. 한국어 직역이 어색한 표현 (예: 空気読めない, 微妙, 〜のくせに)
        2. 일상에서 자주 쓰는 패턴/관용구 (예: 〜すぎる, しょうがない)
        3. 상황 밀착 표현 (연애/고백/이별/직장 등)

        [PHRASE 작성 규칙]
        - JSON은 반드시 한 줄로. 줄바꿈 없이.
        - contextUsage는 1~2문장으로 간단하게.

        [INSIGHT 작성 규칙]
        마크다운 형식. 이모지 적극 활용.
        ## CONTEXT & USAGE
        - 표현의 정확한 뉘앙스와 사용 상황
        - 예제 문장 2~3개 (한자 / 히라가나 / 한국어 번역 세트로)
        💡 한국인이 실수하기 쉬운 부분, 주의사항, 비슷한 표현 비교
        """

        return Future<DailyPhraseResponse, Error> { promise in
            guard let url = URL(string: "\(self.baseURL)?key=\(self.apiKey)") else {
                promise(.failure(GeminiError.invalidURL)); return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let requestBody: [String: Any] = ["contents": [["parts": [["text": prompt]]]]]
            request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error { promise(.failure(error)); return }
                guard let data = data else { promise(.failure(GeminiError.noData)); return }
                do {
                    let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
                        promise(.failure(GeminiError.invalidResponse)); return
                    }
                    print("📦 Daily Phrase Raw: \(text)")
                    guard let result = self.parseDailyPhrase(from: text) else {
                        print("🔴 Daily Phrase 파싱 실패")
                        promise(.failure(GeminiError.parsingError)); return
                    }
                    print("🟢 Daily Phrase 성공!")
                    promise(.success(result))
                } catch {
                    print("🔴 Decoding Error: \(error)")
                    if let err = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("❌ Error Response: \(err)")
                    }
                    promise(.failure(error))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Helper: Daily Phrase 구분자 파싱
    private func parseDailyPhrase(from text: String) -> DailyPhraseResponse? {
        let phraseMarker = "===PHRASE==="
        let insightMarker = "===INSIGHT==="

        guard let phraseRange = text.range(of: phraseMarker),
              let insightRange = text.range(of: insightMarker) else {
            print("⚠️ 구분자 없음, extractJSON 폴백 시도")
            let cleaned = extractJSON(from: text)
            guard let jsonData = cleaned.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(DailyPhraseResponse.self, from: jsonData)
        }

        let jsonRaw = String(text[phraseRange.upperBound..<insightRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStr = extractJSON(from: jsonRaw)

        let insight = String(text[insightRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct PhraseJSON: Codable {
            let japanese: String
            let reading: String
            let meaning: String
            let contextUsage: String
        }

        guard let jsonData = jsonStr.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(PhraseJSON.self, from: jsonData) else {
            print("⚠️ PHRASE JSON 파싱 실패: \(jsonStr)")
            return nil
        }

        return DailyPhraseResponse(
            japanese: parsed.japanese,
            reading: parsed.reading,
            meaning: parsed.meaning,
            contextUsage: parsed.contextUsage,
            aiInsight: insight
        )
    }

    // MARK: - Helper: Extract JSON
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            return String(trimmed[start...end])
        }
        var cleaned = trimmed
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        else if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Word AI Content
struct WordAIContent: Codable {
    let aiContent: String
    let quizData: QuizData?
}

// MARK: - Response Models
struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

// MARK: - Daily Phrase Response
struct DailyPhraseResponse: Codable {
    let japanese: String
    let reading: String
    let meaning: String
    let contextUsage: String
    let aiInsight: String
}

// MARK: - Errors
enum GeminiError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다"
        case .noData: return "데이터를 받지 못했습니다"
        case .invalidResponse: return "응답이 올바르지 않습니다"
        case .parsingError: return "데이터 파싱에 실패했습니다"
        }
    }
}
