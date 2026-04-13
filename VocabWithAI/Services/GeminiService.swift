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

    // MARK: - Default Prompts
    // SettingsView에서 편집 화면 초기값으로도 사용됨

    /// 단어 API 기본 프롬프트 (SettingsView 편집 화면 초기값으로 사용)
        static let defaultWordPrompt = """
        일본어 단어 "{word}"에 대해 아래 형식을 반드시 지켜서 응답해주세요.
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
        한국인 학습자를 위한 마크다운 학습 자료. 이모지 적극 활용. 마치 1타 강사처럼 활기차고 재치 있는 말투를 사용할 것.

        ## 1. 한자 나노 분해 및 스토리텔링 (반드시 단어를 구성하는 '각 한자별로' 분리해서 작성할 것)
        각 한자마다 아래 3가지 요소를 명확히 구분하여 작성할 것:
        - [뼈대 분해] 부수, 음독, 훈독, 모양 분해(어떤 의미를 가진 한자/부수들이 결합했는지 직관적으로 명시)
        - [진짜 어원 (Fact)] 한자가 만들어진 실제 유래와 역사적 배경을, 위에서 분해한 구성 요소의 의미와 연결하여 논리적으로 설명할 것.
        - [뇌피셜 스토리 (MSG)] 쪼개진 구성 요소들의 뜻을 조합하여, 학습자의 머릿속에 시각적으로 확 꽂히는 억지스럽고 재치 있는 과장된 암기 스토리를 창작할 것.

        ## 2. 관련 단어 (고구마 줄기 파생 단어)
        - 이 단어를 구성하는 한자 각각에 대해, 그 한자를 포함한 다른 단어 1-2개씩 제시.
        - 각 단어마다 한자 / 히라가나 읽기 / 뜻 / 짤막한 실전 활용 예문 포함.

        ## 3. 실전 예문
        - 직역투가 아닌 일본 현지에서 가장 많이 쓰는 자연스러운 1티어 예문으로 구성할 것.
        - 각 예문: 일본어 원문(대화 X, 한 문장씩) / 히라가나 읽기 / 한국어 번역 / 상황 설명(이모지) 순서로 작성.

        [응답 예시 - 단어가 "情報"일 경우]
        ===QUIZ===
        {"hiraganaChoices":["じょうほう","じょほう","しょうほう","じょうぼう"],"kanjiChoices":["情報","情法","静報","青報"]}
        ===CONTENT===
        ### 🦴 1. 한자 나노 분해 및 스토리텔링

        **[1] 情 (뜻 정)**
        * **[뼈대 분해]** 부수: 忄 (심방변, 마음) / 음독: ジョウ / 모양 분해: 忄 (마음) + 青 (푸를 청)
        * **[진짜 어원 (Fact)]** 사람의 마음(忄) 깊은 곳에서 우러나오는 푸르고(青) 생생한 본연의 감정이나 있는 그대로의 사실을 의미합니다.
        * **[뇌피셜 스토리 (MSG)]** 내 마음(忄)속 가장 푸르고(青) 순수한 진짜 감정과 팩트! 그것이 바로 나의 진실된 **'뜻(情)'**이다! 💙

        **[2] 報 (알릴 보)**
        * **[뼈대 분해]** 부수: 土 (흙 토) / 음독: ホウ / 모양 분해: 幸 (다행 행) + 卩 (사람의 모습) + 又 (손/또 우)
        * **[진짜 어원 (Fact)]** 옛날에 어떤 일의 결과를 윗사람이나 사람들에게 사실대로 '보고하다, 알리다'라는 데서 유래했습니다.
        * **[뇌피셜 스토리 (MSG)]** 다행히(幸) 무사히 살아 돌아온 사람(卩)이 손(又)을 번쩍 들고 왕에게 승전보를 **'알리는(報)'** 모습! 🙋‍♂️📣

        ### 🍠 2. 관련 단어 (고구마 줄기 파생 단어)

        **[情 (뜻 정) 파생 단어]**
        * **感情 (かんじょう)** : 감정
          * *예:* 感情を抑える (감정을 억누르다)
        * **事情 (じじょう)** : 사정 (어떤 일의 형편)
          * *예:* 個人的な事情で (개인적인 사정으로)

        **[報 (알릴 보) 파생 단어]**
        * **報告 (ほうこく)** : 보고
          * *예:* 上司に報告する (상사에게 보고하다)
        * **予報 (よほう)** : 예보
          * *예:* 天気予報を見る (일기예보를 보다)

        ### 🎯 3. 실전 예문

        **[예문 1: 일상/생존 1티어]**
        ネットで最新の情報を集める。
        ねっとで さいしんの じょうほうを あつめる。
        인터넷으로 최신 정보를 모은다.
        * 📱 꿀팁: 무언가를 검색하고 알아볼 때 가장 기본이 되는 뼈대입니다! '集める(모으다)'와 찰떡궁합이에요.

        **[예문 2: 비즈니스/격식 1티어]**
        情報漏洩には十分注意してください。
        じょうほう ろうえいには じゅうぶん ちゅういして ください。
        정보 유출에는 충분히 주의해 주십시오.
        * 💼 꿀팁: 회사 보안 교육이나 업무 메일에서 숨 쉬듯 등장하는 무시무시한(?) 필수 비즈니스 문장입니다.
        """

    /// 표현 API 기본 프롬프트 (SettingsView 편집 화면 초기값으로 사용)
    static let defaultPhrasePrompt = """
    당신은 한국인 학습자를 위한 전문 일본어 강사이자 JLPT 시험 대비 전문가입니다. 일본어 학습 앱의 "오늘의 표현" 기능에 제공할 JLPT 핵심 문법을 아래 형식을 반드시 지켜서 응답해주세요.

    설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.
    [랜덤 시드: {seed}]
    - 반드시 위 카테고리에 해당하는 JLPT(N4~N3) 필수 문법, 접속어, 또는 문형을 하나 선정할 것.
    - 단순히 특이하거나 유행하는 신조어가 아닌, 실제 JLPT 시험 문법 파트에서 자주 출제되는 형태를 제시할 것.
    - 이전에 자주 쓰인 극기초 표현은 제외할 것.

    ===PHRASE===
    {"japanese":"[선정된 핵심 문법/접속어 (예: ~くせに)]","reading":"[히라가나]","meaning":"[한국어 뜻]","exampleSentence":"[해당 문법이 포함된 전체 일본어 예문]","contextUsage":"[1~2문장 상황 설명]"}

    ===INSIGHT===
    # 1. 「[핵심 문법]」의 의미와 특징
    ## 의미: [핵심 의미]
    ## 특징: [뉘앙스 및 사용 상황]
    ## 주의점: [한국인이 실수하기 쉬운 부분이나 제약 사항을 번호 매겨서 나열]

    # 2. 접속 방법
    ## 동사: [접속 형태] (예: [예시])
    ## い형용사: [접속 형태] (예: [예시])
    ## な형용사: [접속 형태] (예: [예시])
    ## 명사: [접속 형태] (예: [예시])
    *(해당하지 않는 품사가 있다면 생략 가능)*

    # 3. 실전 예문 (한자 / 히라가나 / 한글)
    ## [품사] 결합 예문 1
    ### 한자: [한자 문장]
    ### 히라가나: [히라가나 문장]
    ### 한글: [한국어 번역]

    ## [품사] 결합 예문 2
    ### 한자: [한자 문장]
    ### 히라가나: [히라가나 문장]
    ### 한글: [한국어 번역]

    [작성 규칙]
    - JSON은 반드시 한 줄로. 줄바꿈 없이.
    - japanese 키에는 문장 전체가 아닌 '핵심 문법/접속어' 자체만 넣을 것.
    - exampleSentence 키에 해당 문법이 사용된 전체 문장을 넣을 것.
    - INSIGHT 부분은 반드시 제시된 개조식 포맷(#, ##, ###)을 완벽하게 지켜서 작성할 것.
    """

    // MARK: - Generate Word Content

    func generateWordContent(for word: String) -> AnyPublisher<WordAIContent, Error> {
        // 커스텀 프롬프트가 있으면 사용, 없으면 기본값 사용
        // {word} 플레이스홀더를 실제 단어로 치환
        let template = PromptManager.shared.wordPrompt() ?? GeminiService.defaultWordPrompt
        let prompt = template.replacingOccurrences(of: "{word}", with: word)

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
        let seed = Int.random(in: 100000...999999)
        // 커스텀 프롬프트가 있으면 사용, 없으면 기본값 사용
        // {seed} 플레이스홀더를 랜덤 시드로 치환
        let template = PromptManager.shared.phrasePrompt() ?? GeminiService.defaultPhrasePrompt
        let prompt = template.replacingOccurrences(of: "{seed}", with: "\(seed)")

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
            let exampleSentence: String
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

// MARK: - Models

struct WordAIContent: Codable {
    let aiContent: String
    let quizData: QuizData?
}

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

struct DailyPhraseResponse: Codable {
    let japanese: String
    let reading: String
    let meaning: String
    let exampleSentence: String
    let contextUsage: String
    let aiInsight: String
}

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
