//
//  GeminiService.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import Foundation
import Combine

/// Gemini API와의 통신을 담당하는 서비스 클래스.
/// - 단어 AI 콘텐츠 생성 (generateWordContent)
/// - 오늘의 표현 생성 (generateDailyPhrase)
/// 두 가지 기능을 제공하며, 모두 Combine Publisher로 비동기 결과를 반환한다.
class GeminiService {

    // MARK: - Singleton
    /// 앱 전체에서 공유하는 단일 인스턴스
    static let shared = GeminiService()

    // MARK: - Private Properties

    /// Gemini API 인증 키
    private let apiKey: String

    /// 사용 모델: gemini-2.5-flash
    /// generateContent 엔드포인트로 텍스트 생성 요청
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent"

    private init() {
        self.apiKey = "AIzaSyBgYrNzJFhUzaxS27v9nA5VomxpcClk6Kk"
    }

    // MARK: - Generate Word Content

    /// 일본어 단어에 대한 AI 학습 콘텐츠와 퀴즈 데이터를 생성한다.
    /// - Parameter word: 분석할 일본어 단어 (예: "検索", "食べる")
    /// - Returns: WordAIContent(aiContent + quizData)를 방출하는 Publisher
    /// - 응답 형식: ===QUIZ=== 구분자로 JSON 퀴즈 / ===CONTENT=== 구분자로 마크다운 학습 자료 분리
    func generateWordContent(for word: String) -> AnyPublisher<WordAIContent, Error> {
        let prompt = """
                        일본어 단어 "\(word)"에 대해 아래 형식을 반드시 지켜서 응답해주세요.
                        설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.

                        ===QUIZ===
                        {"hiraganaChoices":["정답히라가나","오답1","오답2","오답3"],"kanjiChoices":["정답한자","오답1","오답2","오답3"]}
                        
                        ===CONTENT===
                        # 1. 한자 분석 (전수 조사)
                        *(중요: "\(word)"에 포함된 한자가 1개든, 2개든, 3개 이상이든 상관없이 **모든 한자**를 각각 별도의 ## 섹션으로 나누어 분석할 것. 절대 일부만 쓰고 생략하지 말 것.)*
                        
                        ## [한자 1] (예: 観)
                        ### 부수 및 획수: [부수명] / [획수]
                        ### 음독과 훈독: [음독] / [훈독]
                        ### 어원 및 유래: [유래]
                        ### 암기 스토리: [연상 암기법]

                        ## [한자 2] (예: 光)
                        ### 부수 및 획수: [부수명] / [획수]
                        ### 음독과 훈독: [음독] / [훈독]
                        ### 어원 및 유래: [유래]
                        ### 암기 스토리: [연상 암기법]

                        ## [한자 3] (예: 客)
                        ### 부수 및 획수: [부수명] / [획수]
                        ### 음독과 훈독: [음독] / [훈독]
                        ### 어원 및 유래: [유래]
                        ### 암기 스토리: [연상 암기법]
                        ...(한자 개수만큼 무한 반복)

                        # 2. 관련 단어 (고구마 줄기)
                        *(중요: 위에서 분석한 **모든 한자 각각**에 대해, 해당 한자가 포함된 다른 단어를 최소 1개씩 반드시 제시할 것.)*
                        
                        ## [한자 1]을 포함하는 단어
                        ### 단어: [단어] ([읽기]) / 뜻: [뜻]
                        ### 예문: [일본어 예문] (해석 포함)

                        ## [한자 2]을 포함하는 단어
                        ### 단어: [단어] ([읽기]) / 뜻: [뜻]
                        ### 예문: [일본어 예문] (해석 포함)

                        ## [한자 3]을 포함하는 단어
                        ### 단어: [단어] ([읽기]) / 뜻: [뜻]
                        ### 예문: [일본어 예문] (해석 포함)
                        ...(모든 한자에 대해 반복)

                        # 3. 실전 예문 (최소 2문장)
                        ## 예문 1
                        ### 원문: [일본어 원문]
                        ### 읽기: [히라가나 읽기]
                        ### 번역: [한국어 번역]
                        ### 상황: [상황 설명 이모지]
                        
                        ## 예문 2
                        ### 원문: [일본어 원문]
                        ### 읽기: [히라가나 읽기]
                        ### 번역: [한국어 번역]
                        ### 상황: [상황 설명 이모지]

                        [QUIZ 작성 규칙]
                        - 정답은 항상 배열의 첫 번째(index 0)에 위치시킬 것.
                        - JSON은 반드시 한 줄로 작성할 것.

                        [CONTENT 작성 규칙]
                        - **단어의 글자 수와 상관없이 모든 구성 한자를 낱개로 쪼개어 분석할 것.**
                        - 반드시 제시된 #, ##, ### 계층 구조를 엄격히 지킬 것.
                        """

        return Future<WordAIContent, Error> { promise in
            guard let url = URL(string: "\(self.baseURL)?key=\(self.apiKey)") else {
                promise(.failure(GeminiError.invalidURL)); return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Gemini API 요청 바디: contents > parts > text 구조
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
                    // ===QUIZ=== / ===CONTENT=== 구분자로 응답 파싱
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

    /// Gemini 응답 텍스트를 ===QUIZ=== / ===CONTENT=== 구분자로 분리하여 WordAIContent로 변환.
    /// - quizData: ===QUIZ=== ~ ===CONTENT=== 사이의 JSON을 디코딩
    /// - aiContent: ===CONTENT=== 이후의 마크다운 텍스트
    /// - 구분자가 없으면 전체 텍스트를 aiContent로 폴백
    private func parseWordAIContent(from text: String) -> WordAIContent {
        let quizMarker = "===QUIZ==="
        let contentMarker = "===CONTENT==="
        guard let quizRange = text.range(of: quizMarker),
              let contentRange = text.range(of: contentMarker) else {
            print("⚠️ 구분자 없음, 전체 텍스트를 aiContent로 저장")
            return WordAIContent(aiContent: text, quizData: nil)
        }

        // QUIZ 구분자와 CONTENT 구분자 사이의 텍스트에서 JSON 추출
        let quizRaw = String(text[quizRange.upperBound..<contentRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let quizJsonStr = extractJSON(from: quizRaw)

        var quizData: QuizData? = nil
        if let jsonData = quizJsonStr.data(using: .utf8) {
            quizData = try? JSONDecoder().decode(QuizData.self, from: jsonData)
            if quizData == nil { print("⚠️ quizData JSON 파싱 실패: \(quizJsonStr)") }
        }

        // CONTENT 구분자 이후 전체가 마크다운 학습 자료
        let aiContent = String(text[contentRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return WordAIContent(aiContent: aiContent, quizData: quizData)
    }

    // MARK: - Generate Daily Phrase

    /// JLPT 핵심 문법이 포함된 오늘의 표현을 생성한다.
    /// - 매 호출마다 랜덤 시드를 주입해 다양한 표현이 나오도록 유도
    /// - 응답 형식: ===PHRASE=== 구분자로 JSON / ===INSIGHT=== 구분자로 마크다운 설명 분리
    /// - Returns: DailyPhraseResponse를 방출하는 Publisher
    func generateDailyPhrase() -> AnyPublisher<DailyPhraseResponse, Error> {
        // 매 요청마다 다른 시드를 넣어 AI가 같은 표현을 반복하지 않도록 유도
        let seed = Int.random(in: 100000...999999)
        let prompt = """
                        당신은 한국인 학습자를 위한 전문 일본어 강사이자 JLPT 시험 대비 전문가입니다. 일본어 학습 앱의 "오늘의 표현" 기능에 제공할 JLPT 핵심 문법을 아래 형식을 반드시 지켜서 응답해주세요.
                        
                        설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.
                        [랜덤 시드: \(seed)]
                        - 반드시 JLPT(N4~N3) 필수 문법, 접속어, 또는 문형을 하나 선정할 것.
                        - 단순히 특이하거나 유행하는 신조어가 아닌, 실제 JLPT 시험 문법 파트에서 자주 출제되는 형태를 제시할 것.
                        
                        ===PHRASE===
                        {"japanese":"[선정된 핵심 문법/접속어 (예: ~くせに)]","reading":"[히라가나]","meaning":"[한국어 뜻]","exampleSentence":"[해당 문법이 포함된 전체 일본어 예문]","contextUsage":"[1~2문장 상황 설명]"}
                        
                        ===INSIGHT===
                        # 1. 「[핵심 문법]」의 의미와 특징
                        ## 의미: [핵심 의미]
                        ## 특징: [뉘앙스 및 사용 상황]
                        ## 주의점: [한국인이 실수하기 쉬운 부분이나 제약 사항을 번호 매겨서 나열]
                        
                        # 2. 접속 방법
                        *(주의: 해당 문법이 접속할 수 있는 '모든 품사(동사, い/な형용사, 명사)'의 접속 형태를 빠짐없이 전부 나열할 것. 절대 1개만 쓰고 넘어가거나 임의로 축소하지 말 것. 문법적으로 아예 불가능한 품사만 생략할 것.)*
                        ## 동사: [접속 형태] (예: [예시])
                        ## い형용사: [접속 형태] (예: [예시])
                        ## な형용사: [접속 형태] (예: [예시])
                        ## 명사: [접속 형태] (예: [예시])
                        
                        # 3. 실전 예문 (한자 / 히라가나 / 한글)
                        *(주의: 위 '2. 접속 방법'에서 명시한 품사의 개수와 정확히 일치하게 예문을 모두 작성할 것. 2번에서 4개의 품사를 설명했다면 예문도 반드시 4개가 나와야 함.)*
                        ## [품사] 결합 예문
                        ### 한자: [한자 문장]
                        ### 히라가나: [히라가나 문장]
                        ### 한글: [한국어 번역]
                        
                        ## [품사] 결합 예문
                        ### 한자: [한자 문장]
                        ### 히라가나: [히라가나 문장]
                        ### 한글: [한국어 번역]
                        ...(위에서 설명한 품사 개수만큼 반복 작성)
                        
                        [작성 규칙]
                        - JSON은 반드시 한 줄로. 줄바꿈 없이.
                        - japanese 키에는 문장 전체가 아닌 '핵심 문법/접속어' 자체만 넣을 것.
                        - exampleSentence 키에 해당 문법이 사용된 전체 문장을 넣을 것.
                        - INSIGHT 부분은 반드시 제시된 개조식 포맷(#, ##, ###)을 완벽하게 지켜서 작성할 것.
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
                    // ===PHRASE=== / ===INSIGHT=== 구분자로 응답 파싱
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

    /// Gemini 응답 텍스트를 ===PHRASE=== / ===INSIGHT=== 구분자로 분리하여 DailyPhraseResponse로 변환.
    /// - PHRASE 구간: JSON (japanese, reading, meaning, exampleSentence, contextUsage)
    /// - INSIGHT 구간: 마크다운 상세 설명 (aiInsight)
    /// - 구분자가 없으면 extractJSON 폴백 시도
    /// - Returns: 파싱 성공 시 DailyPhraseResponse, 실패 시 nil
    private func parseDailyPhrase(from text: String) -> DailyPhraseResponse? {
        let phraseMarker = "===PHRASE==="
        let insightMarker = "===INSIGHT==="

        guard let phraseRange = text.range(of: phraseMarker),
              let insightRange = text.range(of: insightMarker) else {
            // 구분자가 없는 경우 전체에서 JSON 추출 시도 (폴백)
            print("⚠️ 구분자 없음, extractJSON 폴백 시도")
            let cleaned = extractJSON(from: text)
            guard let jsonData = cleaned.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(DailyPhraseResponse.self, from: jsonData)
        }

        // PHRASE ~ INSIGHT 사이에서 JSON 추출
        let jsonRaw = String(text[phraseRange.upperBound..<insightRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStr = extractJSON(from: jsonRaw)

        // INSIGHT 이후 전체가 마크다운 설명
        let insight = String(text[insightRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // aiInsight를 제외한 중간 파싱용 내부 모델.
        // aiInsight는 JSON 밖(===INSIGHT=== 이후)에서 별도로 가져오기 때문에 여기서 제외
        struct PhraseJSON: Codable {
            let japanese: String
            let reading: String
            let meaning: String
            let exampleSentence: String  // 해당 문법이 포함된 전체 예문
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
            exampleSentence: parsed.exampleSentence,
            contextUsage: parsed.contextUsage,
            aiInsight: insight
        )
    }

    // MARK: - Helper: Extract JSON

    /// 텍스트에서 JSON 객체 부분만 추출한다.
    /// - 첫 번째 { 부터 마지막 } 까지를 JSON으로 간주 (가장 신뢰도 높은 방법)
    /// - { } 가 없으면 마크다운 코드 펜스(```json, ```)를 제거하고 반환
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // { ~ } 범위로 JSON 직접 추출
        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            return String(trimmed[start...end])
        }

        // 폴백: 마크다운 코드 펜스 제거
        var cleaned = trimmed
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        else if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Word AI Content

/// generateWordContent의 응답을 담는 모델.
/// - aiContent: 마크다운 형식의 학습 자료 (WordDetailView에서 렌더링)
/// - quizData: 히라가나/한자 퀴즈 선지 (FlashcardView, MultipleChoiceQuizView에서 사용)
struct WordAIContent: Codable {
    let aiContent: String
    let quizData: QuizData?
}

// MARK: - Response Models

/// Gemini API 최상위 응답 구조
struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

/// 응답 후보 1개. 보통 candidates[0]만 사용
struct Candidate: Codable {
    let content: Content
}

/// 메시지 콘텐츠. role(model/user)과 parts 배열로 구성
struct Content: Codable {
    let parts: [Part]
}

/// 실제 텍스트 응답이 담긴 단위
struct Part: Codable {
    let text: String
}

// MARK: - Daily Phrase Response

/// generateDailyPhrase의 응답을 담는 모델.
/// parseDailyPhrase에서 생성되어 DailyPhraseViewModel로 전달됨.
/// DailyPhrase 모델로 변환 후 앱 내부에서 사용
struct DailyPhraseResponse: Codable {
    /// 핵심 문법/접속어 (예: ~くせに)
    let japanese: String
    /// 히라가나 읽기
    let reading: String
    /// 한국어 뜻
    let meaning: String
    /// 해당 문법이 포함된 전체 예문
    let exampleSentence: String
    /// 1~2문장 사용 상황 설명
    let contextUsage: String
    /// ===INSIGHT=== 이후의 마크다운 상세 설명 전체
    let aiInsight: String
}

// MARK: - Errors

/// GeminiService에서 발생 가능한 에러 케이스
enum GeminiError: Error, LocalizedError {
    case invalidURL       // baseURL + apiKey 조합 오류
    case noData           // 서버 응답은 왔지만 data가 nil
    case invalidResponse  // candidates 또는 parts가 비어있음
    case parsingError     // 구분자 파싱 또는 JSON 디코딩 실패

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다"
        case .noData: return "데이터를 받지 못했습니다"
        case .invalidResponse: return "응답이 올바르지 않습니다"
        case .parsingError: return "데이터 파싱에 실패했습니다"
        }
    }
}
