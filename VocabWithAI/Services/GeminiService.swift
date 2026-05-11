//
//  GeminiService.swift
//  VocabApp
//
//  Created on 2026-02-03
//  Refactored on 2026-04-27 — Cloud Functions 프록시 전환
//

import Foundation
import Combine
import FirebaseFunctions
import FirebaseAuth

class GeminiService {

    static let shared = GeminiService()

    private init() {}

    /// 매번 호출 시 새로 가져옴 (싱글톤 캐시 X)
    private var functions: Functions {
        Functions.functions(region: "asia-northeast3")
    }

    // MARK: - Default Prompts (SettingsView 편집 화면 초기값으로만 사용)
    // 실제 프롬프트는 Cloud Functions 안에 있음.
    // 사용자가 SettingsView에서 커스텀 프롬프트 저장하면 그것만 Functions로 전달.

    /// 단어 API 기본 프롬프트 (SettingsView 편집 화면 초기값으로 사용)
    static let defaultWordPrompt = """
    일본어 단어 "{word}"에 대해 아래 형식을 반드시 지켜서 응답해주세요.
    설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.

    ===QUIZ===
    {"hiraganaChoices":["정답히라가나","오답1","오답2","오답3"],"kanjiChoices":["정답한자","오답1","오답2","오답3"]}
    ===CONTENT===
    {"summary":"...","kanjiBreakdowns":[...],"relatedWords":[...],"examples":[...]}

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
    한국인 학습자를 위한 JSON 데이터. 마치 1타 강사처럼 활기차고 재치 있는 말투를 사용할 것.
    반드시 아래 스키마를 정확히 지킬 것. 주석/설명/마크다운/코드펜스 금지. 순수 JSON 한 덩어리만.

    스키마:
    {
      "summary": "이 단어의 핵심 의미를 한 문장으로 요약. 각 한자의 뜻이 자연스럽게 녹아들게 작성.",
      "kanjiBreakdowns": [
        {
          "kanji": "단일 한자 1글자 (예: 勇)",
          "meaning": "한국어 훈·뜻 (예: 날랠 용 / 용감할 용)",
          "onyomi": "음독 + 로마자 병기 (예: ユウ (YUU))",
          "kunyomi": "훈독 + 로마자 + 의미 (예: いさ-む (isa-mu) — 용기를 내다, 기운을 내다). 훈독 없으면 빈 문자열.",
          "radical": "부수 한자 + 이름 (예: 力 (힘 력))",
          "components": [
            {
              "char": "구성 요소 한자 1글자 (예: 甬)",
              "meaning": "구성 요소의 훈·뜻 (예: 솟아오를 용)",
              "description": "해당 요소가 가지는 의미를 한 문장으로 (예: 무언가가 솟아오르거나 뚫고 나가는 모양)"
            }
          ],
          "fact": "진짜 어원. 구성 요소들을 실제 역사/자원적으로 연결한 설명. 2~3문장.",
          "msg": "뇌피셜 스토리. 구성 요소들의 뜻을 조합한 억지스럽고 시각적인 암기용 과장 스토리. 1~2문장. 이모지 1~3개 포함 가능."
        }
      ],
      "relatedWords": [
        {
          "sourceKanji": "파생의 출발점이 된 한자 1글자 (예: 勇)",
          "words": [
            {
              "kanji": "단어 한자 표기 (예: 勇者)",
              "reading": "히라가나 읽기 (예: ゆうしゃ)",
              "meaning": "한국어 뜻 (예: 용사)",
              "exampleJP": "짧은 실전 예문 일본어 원문 (예: 勇者が魔王を倒した。)",
              "exampleKR": "예문 한국어 번역 (예: 용사가 마왕을 쓰러뜨렸다.)"
            }
          ]
        }
      ],
      "examples": [
        {
          "jp": "일본어 원문 한 문장. 대화문 금지.",
          "furigana": "전체 문장의 히라가나 읽기. 어절 단위로 공백을 넣을 것.",
          "kr": "자연스러운 한국어 번역",
          "tipEmoji": "문맥에 맞는 이모지 1개 (예: ✨, 💪, 💬, 💼, 📱)",
          "tip": "실전 활용 꿀팁 한 문장. 함께 쓰는 표현이나 뉘앙스 포인트."
        }
      ]
    }

    [작성 규칙 상세]
    - summary: 이 단어의 핵심 의미를 20~35자 내외의 짧고 임팩트 있는 한 문장으로. 각 한자의 뜻이 자연스럽게 녹아들게 작성. 한자 뒤에 괄호로 원문 한자를 병기할 수 있음 (예: "솟구치는(勇) 뜨거운 에너지(気)"). 이모지 금지. 마크다운 볼드(**) 금지. 문장 끝은 "~라는 뜻", "~을 의미해요" 등 담백하게. 한자가 없는 단어는 단어의 뜻을 풀어서 한 문장으로 작성.
    - kanjiBreakdowns: 단어를 구성하는 각 한자마다 1개씩. "勇気"면 2개, "情報"면 2개, "図書館"이면 3개. 순서는 단어에 나오는 순서대로.
    - 단어가 순수 히라가나/가타카나라 한자가 없으면 kanjiBreakdowns는 빈 배열 []. 이 경우에도 summary, relatedWords, examples는 정상적으로 채울 것.
    - components: 한자를 쪼갠 의미 있는 구성 요소 1~4개. 의미 없는 획 분해는 금지. 부수와 겹쳐도 괜찮음.
    - relatedWords: 단어를 구성하는 각 한자별로 그룹 1개씩. 각 그룹 내 words는 1~2개. 원본 단어 자기 자신은 제외.
    - examples: 정확히 3개. 직역투 금지, 일본 현지에서 실제로 쓰는 1티어 자연스러운 문장. 일상/비즈니스/감정표현 등 상황을 다양하게 섞을 것.
    - 모든 문자열은 JSON 규격상 큰따옴표 이스케이프 주의. 줄바꿈 문자(\\n) 쓰지 말고 한 문장으로 작성.

    [응답 예시 - 단어가 "勇気"일 경우]
    ===QUIZ===
    {"hiraganaChoices":["ゆうき","ようき","ゆうけ","ゆき"],"kanjiChoices":["勇気","勇敢","元気","勇者"]}
    ===CONTENT===
    {"summary":"내면에서 솟구치는(勇) 뜨거운 마음의 에너지(気)라는 뜻","kanjiBreakdowns":[{"kanji":"勇","meaning":"날랠 용 / 용감할 용","onyomi":"ユウ (YUU)","kunyomi":"いさ-む (isa-mu) — 용기를 내다, 기운을 내다","radical":"力 (힘 력)","components":[{"char":"甬","meaning":"솟아오를 용","description":"무언가가 솟아오르거나 뚫고 나가는 모양을 나타내는 부분이에요!"},{"char":"力","meaning":"힘 력","description":"글자 그대로 '힘'을 의미해요."}],"fact":"'甬(통할 용)'은 '솟아오르다', '뚫고 나아가다'라는 의미를 나타내고, '力(힘 력)'은 글자 그대로 '힘'을 의미합니다. 이 둘이 합쳐져 마음속에서 강한 힘이 솟아나 어떤 어려움도 뚫고 나아갈 수 있는 '용맹함', '용기'를 표현하게 되었어요.","msg":"두려움 속에서도 내면에서 불끈! 솟아오르는(甬) 강한 힘(力)! 그래! 이게 바로 모든 것을 뚫고 나아갈 '용기(勇)'다! 절대 쫄지 마! 💪🔥🚀"},{"kanji":"気","meaning":"기운 기","onyomi":"キ (KI), ケ (KE)","kunyomi":"いき (iki) — 숨","radical":"气 (기운 기)","components":[{"char":"气","meaning":"기운 기","description":"김이나 수증기가 피어오르는 모양을 본뜬 상형문자예요."}],"fact":"이 한자는 끓는 물에서 피어오르는 김이나 하늘의 구름을 본떠 만든 상형문자입니다. 원래는 '공기', '기체', '수증기' 같은 물리적인 기운을 나타냈으나, 점차 생명체의 '생기', '기운', '정신', 나아가 분위기나 느낌 등의 추상적인 의미로 확장되었답니다!","msg":"보글보글 끓는 물에서 뽀얗게 피어오르는 수증기(气)처럼, 우리의 몸과 마음을 채우는 생명의 '기운(気)'! 🌬️✨ 숨 쉬는 모든 순간이 에너지!"}],"relatedWords":[{"sourceKanji":"勇","words":[{"kanji":"勇者","reading":"ゆうしゃ","meaning":"용사","exampleJP":"勇者が魔王を倒した。","exampleKR":"용사가 마왕을 쓰러뜨렸다."},{"kanji":"勇敢","reading":"ゆうかん","meaning":"용감","exampleJP":"勇敢な行動","exampleKR":"용감한 행동"}]},{"sourceKanji":"気","words":[{"kanji":"元気","reading":"げんき","meaning":"건강, 활기","exampleJP":"お元気ですか。","exampleKR":"잘 지내세요? 건강하세요?"},{"kanji":"天気","reading":"てんき","meaning":"날씨","exampleJP":"明日の天気は晴れだ。","exampleKR":"내일 날씨는 맑음이다."}]}],"examples":[{"jp":"新しいことに挑戦する勇気がほしい。","furigana":"あたらしいことに ちょうせんする ゆうきが ほしい。","kr":"새로운 일에 도전할 용기가 필요해. (가지고 싶어.)","tipEmoji":"✨","tip":"뭔가 망설여질 때, 혹은 친구를 격려할 때 아주 많이 쓰이는 표현! 'ほしい(원하다)'와 찰떡궁합!"},{"jp":"彼には困難に立ち向かう勇気がある。","furigana":"かれには こんなんに たちむかう ゆうきが ある。","kr":"그에게는 곤란에 맞설 용기가 있다.","tipEmoji":"💪","tip":"힘든 상황을 마주했을 때, 누군가의 '용기'를 칭찬하거나 이야기할 때 쓰는 멋진 표현! '立ち向かう(맞서다)'와 함께 쓰면 시너지 폭발!"},{"jp":"正直に話す勇気がなかった。","furigana":"しょうじきに はなす ゆうきが なかった。","kr":"솔직하게 말할 용기가 없었다.","tipEmoji":"💬","tip":"솔직한 고백이나 어려운 말을 해야 할 때, '勇気がない(용기가 없다)'는 표현으로 자신의 솔직한 마음을 나타낼 수 있어요!"}]}
    """


    /// 표현 API 기본 프롬프트 (SettingsView 편집 화면 초기값으로 사용)
    static let defaultPhrasePrompt = """
    당신은 한국인 학습자를 위한 전문 일본어 강사이자 JLPT 시험 대비 전문가입니다. 인사말, 과도한 친절, 아부성 멘트 등 불필요한 서론/결론은 일절 배제하고, 냉철하고 명쾌하게 핵심만 짚어주는 톤을 유지하세요. 일본어 학습 앱의 "오늘의 표현" 기능에 제공할 JLPT(N4~N3) 핵심 문법을 아래 형식을 반드시 지켜서 응답해주세요.

    [랜덤 시드: {seed}]
    이 시드를 진짜로 활용해서 매번 다른 문법을 골라야 합니다.

    [참고용 문법 풀 — 이게 전부는 아님, 이외에도 좋은 N4~N3 문법이 있다면 자유롭게 선택 가능]
    - 원인/이유: から、ので、ため(に)、おかげで、せいで、ばかりに、だけに、わけだ、あまり(に)
    - 추측/추정: はずだ、はずがない、らしい、ようだ、みたいだ、に違いない、に決まっている、っぽい
    - 양보/역접: のに、ても、くせに、ながら(も)、にもかかわらず、からといって
    - 한정/강조: しか〜ない、こそ、さえ、まで、ほど、に限る、にすぎない
    - 시간/순서: まえに、うちに、間(に)、たびに、〜たとたん、ところだ、〜次第、〜たばかり
    - 변화/완료: ようになる、ことになる、ようにする、ことにする、つつある、〜てしまう、〜ておく
    - 의무/허가/금지: なければならない、べきだ、てもいい、てはいけない、ことだ
    - 가능/난이도: 〜られる(가능형)、やすい、にくい、がたい、かねる、っこない
    - 비교/유사/조건: より、ほど〜ない、〜ような、〜とおり(に)、〜たら、〜なら、〜限り
    - 전문/인용/수동·사역: 〜そうだ(전문)、〜という、〜とのこと、〜って、〜られる(수동)、〜させる、〜させられる

    [작성 규칙]
    - 다양성을 우선하되, 가끔은 이전에 다뤘던 문법을 복습 차원으로 다시 다뤄도 좋음.
    - 위 풀에 있는 항목들이 핵심이므로 우선 다룰 것. 풀에 있는 모든 항목이 골고루 등장하는 게 목표.
    - 기초부터 살짝 도전적인 표현까지 골고루 다룰 것. 너무 한쪽 난이도에 치우치지 말 것.
    - JSON은 반드시 한 줄로. 줄바꿈 없이.
    - japanese 키에는 문장 전체가 아닌 '핵심 문법/접속어' 자체만 넣을 것.
    - exampleSentence 키에 해당 문법이 사용된 전체 일본어 예문을 넣을 것.
    - exampleFurigana 키에 exampleSentence 전체의 히라가나 읽기를 넣을 것. 어절 단위 공백 없이 자연스럽게 이어서 작성.
    - exampleKorean 키에 exampleSentence의 자연스러운 한국어 번역을 넣을 것.
    - INSIGHT 부분은 반드시 제시된 개조식 포맷(#, ##, ###)을 완벽하게 지켜서 작성할 것.
    - 품사별 접속(섹션 2)에서 한 품사당 한 줄에 공식은 1개만 작성. 여러 형태가 있으면 품사를 별도 줄로 분리(예: ## 동사(て형): ..., ## 동사(ます형): ...).

    설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.

    ===PHRASE===
    {"japanese":"[선정된 핵심 문법/접속어]","reading":"[핵심 문법의 히라가나]","meaning":"[핵심 문법의 한국어 뜻]","exampleSentence":"[해당 문법이 포함된 전체 일본어 예문]","exampleFurigana":"[exampleSentence의 전체 히라가나]","exampleKorean":"[exampleSentence의 한국어 번역]","contextUsage":"[1~2문장 상황 설명]"}

    ===INSIGHT===
    # 1. 「[핵심 문법]」의 의미와 특징
    ## 의미: [직관적인 한국어 뜻]
    ## 비유: [머릿속에 그림이 확 그려지는 찰떡같은 비유나 상황]
    ## 뉘앙스와 주의점: [원어민이 실제로 쓰는 리얼한 뉘앙스와, 한국인이 실수하기 쉬운 부분(접속 예외 등)을 명쾌하게 설명]

    # 2. 품사별 조립 방법 (접속)
    ## 동사: [접속 형태] (예: [동사 원형] ➔ [조립된 형태])
    ## い형용사: [접속 형태] (예: [원형] ➔ [조립된 형태])
    ## な형용사: [접속 형태] (예: [원형] ➔ [조립된 형태])
    ## 명사: [접속 형태] (예: [명사] ➔ [조립된 형태])
    *(해당하지 않는 품사가 있다면 생략 가능)*

    # 3. 실전 통문장
    ## [상황 설명 혹은 품사 결합] 예문 1
    ### 한자: [한자 문장]
    ### 히라가나: [히라가나 문장]
    ### 한글: [한국어 번역]

    ## [상황 설명 혹은 품사 결합] 예문 2
    ### 한자: [한자 문장]
    ### 히라가나: [히라가나 문장]
    ### 한글: [한국어 번역]

    ---
    [예시 응답: 〜に違いない 를 선정했을 경우]

    ===PHRASE===
    {"japanese":"〜に違いない","reading":"にちがいない","meaning":"~임에 틀림없다","exampleSentence":"あの店は行列ができているから、美味しいに違いない。","exampleFurigana":"あのみせはぎょうれつができているから、おいしいにちがいない。","exampleKorean":"저 가게는 줄이 서 있으니까, 맛있을 게 틀림없다.","contextUsage":"눈앞의 단서나 정황을 토대로 거의 100% 확신하는 추측을 표현할 때 사용합니다."}

    ===INSIGHT===
    # 1. 「〜に違いない」의 의미와 특징
    ## 의미: ~임에 틀림없다, 분명히 ~다
    ## 비유: 단서를 다 모은 탐정이 "이 사건의 범인은 너야!"라고 단언하는 느낌. 단순 추측이 아니라, 거의 확신에 가까운 강한 추측.
    ## 뉘앙스와 주의점: 「はずだ」보다 더 강한 확신, 「だろう」보다 훨씬 단정적. 회화체에서는 살짝 딱딱해서 「絶対〜だ」나 「きっと〜だろう」가 자연스러울 때가 있음.

    # 2. 품사별 조립 방법 (접속)
    ## 동사: 보통형 + に違いない (예: 来る ➔ 来るに違いない)
    ## い형용사: 보통형 + に違いない (예: 美味しい ➔ 美味しいに違いない)
    ## な형용사: 어간 + に違いない (예: 元気だ ➔ 元気に違いない)
    ## 명사: 명사 + に違いない (예: 学生 ➔ 学生に違いない)

    # 3. 실전 통문장
    ## 정황 증거를 바탕으로 한 강한 추측 (동사 결합)
    ### 한자: 電気がついているから、誰かが家にいるに違いない。
    ### 히라가나: でんきがついているから、だれかがいえにいるにちがいない。
    ### 한글: 불이 켜져 있으니까, 누군가 집에 있는 게 틀림없어.

    ## 평소 행동을 바탕으로 한 확신 (동사 결합)
    ### 한자: 彼は毎日勉強しているから、試験に合格するに違いない。
    ### 히라가나: かれはまいにちべんきょうしているから、しけんにごうかくするにちがいない。
    ### 한글: 그는 매일 공부하고 있으니까, 시험에 합격할 게 틀림없다.
    """

    // MARK: - Generate Word Content

    func generateWordContent(for word: String) -> AnyPublisher<WordAIContent, Error> {
        // 커스텀 프롬프트가 있으면 그것만 서버로 전달.
        // 없으면 nil → 서버의 기본 프롬프트 사용.
        let customPrompt = PromptManager.shared.wordPrompt()

        var data: [String: Any] = ["word": word]
        if let customPrompt = customPrompt {
            data["customPrompt"] = customPrompt
        }


        return Future<WordAIContent, Error> { promise in
            self.functions.httpsCallable("generateWordContent").call(data) { result, error in
                if let error = error {
                    print("🔴 Functions 호출 실패: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }

                guard let dict = result?.data as? [String: Any],
                      let text = dict["text"] as? String else {
                    promise(.failure(GeminiError.invalidResponse))
                    return
                }

                print("📦 Raw Response: \(text)")
                let parsed = self.parseWordAIContent(from: text)
                print("✅ quizData: \(parsed.quizData != nil ? "파싱 성공" : "없음")")
                promise(.success(parsed))
            }
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

        // --- QUIZ 파싱 ---
        let quizRaw = String(text[quizRange.upperBound..<contentRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let quizJsonStr = extractJSON(from: quizRaw)
        var quizData: QuizData? = nil
        if let jsonData = quizJsonStr.data(using: .utf8) {
            quizData = try? JSONDecoder().decode(QuizData.self, from: jsonData)
            if quizData == nil { print("⚠️ quizData JSON 파싱 실패: \(quizJsonStr)") }
        }

        // --- CONTENT 파싱 ---
        let aiContent = String(text[contentRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let decoded = AIContent.decode(from: aiContent) {
            print("✅ AIContent 파싱 성공 — summary:\(decoded.summary != nil ? "O" : "X") / kanji:\(decoded.kanjiBreakdowns.count) / related:\(decoded.relatedWords.count) / ex:\(decoded.examples.count)")
        } else {
            print("⚠️ AIContent 파싱 실패 — raw 저장 (포맷 깨짐)")
        }

        return WordAIContent(aiContent: aiContent, quizData: quizData)
    }

    // MARK: - Generate Daily Phrase

    func generateDailyPhrase() -> AnyPublisher<DailyPhraseResponse, Error> {
        let customPrompt = PromptManager.shared.phrasePrompt()

        var data: [String: Any] = [:]
        if let customPrompt = customPrompt {
            data["customPrompt"] = customPrompt
        }

        return Future<DailyPhraseResponse, Error> { promise in
            self.functions.httpsCallable("generateDailyPhrase").call(data) { result, error in
                if let error = error {
                    print("🔴 Functions 호출 실패: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }

                guard let dict = result?.data as? [String: Any],
                      let text = dict["text"] as? String else {
                    promise(.failure(GeminiError.invalidResponse))
                    return
                }

                print("📦 Daily Phrase Raw: \(text)")
                guard let parsed = self.parseDailyPhrase(from: text) else {
                    print("🔴 Daily Phrase 파싱 실패")
                    promise(.failure(GeminiError.parsingError))
                    return
                }
                print("🟢 Daily Phrase 성공!")
                promise(.success(parsed))
            }
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
            let exampleFurigana: String?
            let exampleKorean: String?
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
            exampleFurigana: parsed.exampleFurigana,
            exampleKorean: parsed.exampleKorean,
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

struct DailyPhraseResponse: Codable {
    let japanese: String
    let reading: String
    let meaning: String
    let exampleSentence: String
    let exampleFurigana: String?
    let exampleKorean: String?
    let contextUsage: String
    let aiInsight: String
}

enum GeminiError: Error, LocalizedError {
    case invalidResponse
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "응답이 올바르지 않습니다"
        case .parsingError: return "데이터 파싱에 실패했습니다"
        }
    }
}
