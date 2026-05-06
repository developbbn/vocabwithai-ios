/**
 * VocabWithAI Cloud Functions
 *
 * iOS 클라이언트에서 호출하는 Gemini 프록시 함수들.
 * - generateWordContent: 단어 학습 콘텐츠 + 퀴즈 데이터 생성
 * - generateDailyPhrase: 오늘의 표현 생성
 *
 * 인증된 사용자만 호출 가능 (Firebase Auth 토큰 자동 검증).
 * 503/429 시 자동 재시도 + primary 모델 실패 시 fallback 모델로 자동 전환.
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {GoogleGenerativeAI} from "@google/generative-ai";

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

const PRIMARY_MODEL = "gemini-2.5-flash";
const FALLBACK_MODEL = "gemini-2.0-flash";

// ============================================================
// generateWordContent
// ============================================================

export const generateWordContent = onCall(
  {
    secrets: [GEMINI_API_KEY],
    region: "asia-northeast3",
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    }

    const word = request.data?.word as string | undefined;
    const customPrompt = request.data?.customPrompt as string | undefined;

    if (!word || typeof word !== "string" || word.trim().length === 0) {
      throw new HttpsError("invalid-argument", "word 파라미터가 필요합니다.");
    }

    const template = customPrompt || DEFAULT_WORD_PROMPT;
    const prompt = template.replace(/\{word\}/g, word);

    try {
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
      const text = await generateWithFallback(genAI, prompt);

      console.log(`✅ generateWordContent 성공: ${word} (uid: ${request.auth.uid})`);
      return {text};
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Unknown error";
      console.error(`🔴 Gemini 호출 실패: ${message}`);
      throw new HttpsError("internal", `Gemini 호출 실패: ${message}`);
    }
  }
);

// ============================================================
// generateDailyPhrase
// ============================================================

export const generateDailyPhrase = onCall(
  {
    secrets: [GEMINI_API_KEY],
    region: "asia-northeast3",
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    }

    const customPrompt = request.data?.customPrompt as string | undefined;
    const seed = Math.floor(Math.random() * 900000) + 100000;
    const template = customPrompt || DEFAULT_PHRASE_PROMPT;
    const prompt = template.replace(/\{seed\}/g, String(seed));

    try {
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
      const text = await generateWithFallback(genAI, prompt);

      console.log(`✅ generateDailyPhrase 성공 (uid: ${request.auth.uid})`);
      return {text};
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Unknown error";
      console.error(`🔴 Gemini 호출 실패: ${message}`);
      throw new HttpsError("internal", `Gemini 호출 실패: ${message}`);
    }
  }
);

// ============================================================
// Helpers
// ============================================================

/**
 * Primary 모델로 호출. 503/429면 재시도. 그래도 실패하면 fallback 모델로 1회 시도.
 * @param genAI GoogleGenerativeAI 인스턴스
 * @param prompt 보낼 프롬프트
 * @return Gemini 응답 텍스트
 */
async function generateWithFallback(
  genAI: GoogleGenerativeAI,
  prompt: string,
): Promise<string> {
  try {
    return await callWithRetry(async () => {
      const model = genAI.getGenerativeModel({model: PRIMARY_MODEL});
      const result = await model.generateContent(prompt);
      return result.response.text();
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "";
    const isOverload = message.includes("503") ||
                       message.includes("429") ||
                       message.includes("overloaded");

    if (!isOverload) throw error;

    console.log(`⚠️ ${PRIMARY_MODEL} 과부하, ${FALLBACK_MODEL}로 fallback`);
    const model = genAI.getGenerativeModel({model: FALLBACK_MODEL});
    const result = await model.generateContent(prompt);
    return result.response.text();
  }
}

/**
 * 503/429 에러 시 자동 재시도. Exponential backoff: 1초 → 2초 → 4초.
 * @param fn 재시도할 비동기 함수
 * @param maxRetries 최대 재시도 횟수
 * @param initialDelayMs 첫 재시도 지연 ms
 * @return 함수 실행 결과
 */
async function callWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  initialDelayMs = 1000,
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: unknown) {
      lastError = error;
      const message = error instanceof Error ? error.message : "";
      const isRetriable = message.includes("503") ||
                          message.includes("429") ||
                          message.includes("overloaded");

      if (!isRetriable || attempt === maxRetries - 1) {
        throw error;
      }

      const delay = initialDelayMs * Math.pow(2, attempt);
      console.log(`⏳ 재시도 ${attempt + 1}/${maxRetries} (${delay}ms 후)`);
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}

// ============================================================
// 기본 프롬프트
// ============================================================

const DEFAULT_WORD_PROMPT = `일본어 단어 "{word}"에 대해 아래 형식을 반드시 지켜서 응답해주세요.
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
{"summary":"내면에서 솟구치는(勇) 뜨거운 마음의 에너지(気)라는 뜻","kanjiBreakdowns":[{"kanji":"勇","meaning":"날랠 용 / 용감할 용","onyomi":"ユウ (YUU)","kunyomi":"いさ-む (isa-mu) — 용기를 내다, 기운을 내다","radical":"力 (힘 력)","components":[{"char":"甬","meaning":"솟아오를 용","description":"무언가가 솟아오르거나 뚫고 나가는 모양을 나타내는 부분이에요!"},{"char":"力","meaning":"힘 력","description":"글자 그대로 '힘'을 의미해요."}],"fact":"'甬(통할 용)'은 '솟아오르다', '뚫고 나아가다'라는 의미를 나타내고, '力(힘 력)'은 글자 그대로 '힘'을 의미합니다. 이 둘이 합쳐져 마음속에서 강한 힘이 솟아나 어떤 어려움도 뚫고 나아갈 수 있는 '용맹함', '용기'를 표현하게 되었어요.","msg":"두려움 속에서도 내면에서 불끈! 솟아오르는(甬) 강한 힘(力)! 그래! 이게 바로 모든 것을 뚫고 나아갈 '용기(勇)'다! 절대 쫄지 마! 💪🔥🚀"},{"kanji":"気","meaning":"기운 기","onyomi":"キ (KI), ケ (KE)","kunyomi":"いき (iki) — 숨","radical":"气 (기운 기)","components":[{"char":"气","meaning":"기운 기","description":"김이나 수증기가 피어오르는 모양을 본뜬 상형문자예요."}],"fact":"이 한자는 끓는 물에서 피어오르는 김이나 하늘의 구름을 본떠 만든 상형문자입니다. 원래는 '공기', '기체', '수증기' 같은 물리적인 기운을 나타냈으나, 점차 생명체의 '생기', '기운', '정신', 나아가 분위기나 느낌 등의 추상적인 의미로 확장되었답니다!","msg":"보글보글 끓는 물에서 뽀얗게 피어오르는 수증기(气)처럼, 우리의 몸과 마음을 채우는 생명의 '기운(気)'! 🌬️✨ 숨 쉬는 모든 순간이 에너지!"}],"relatedWords":[{"sourceKanji":"勇","words":[{"kanji":"勇者","reading":"ゆうしゃ","meaning":"용사","exampleJP":"勇者が魔王を倒した。","exampleKR":"용사가 마왕을 쓰러뜨렸다."},{"kanji":"勇敢","reading":"ゆうかん","meaning":"용감","exampleJP":"勇敢な行動","exampleKR":"용감한 행동"}]},{"sourceKanji":"気","words":[{"kanji":"元気","reading":"げんき","meaning":"건강, 활기","exampleJP":"お元気ですか。","exampleKR":"잘 지내세요? 건강하세요?"},{"kanji":"天気","reading":"てんき","meaning":"날씨","exampleJP":"明日の天気は晴れだ。","exampleKR":"내일 날씨는 맑음이다."}]}],"examples":[{"jp":"新しいことに挑戦する勇気がほしい。","furigana":"あたらしいことに ちょうせんする ゆうきが ほしい。","kr":"새로운 일에 도전할 용기가 필요해. (가지고 싶어.)","tipEmoji":"✨","tip":"뭔가 망설여질 때, 혹은 친구를 격려할 때 아주 많이 쓰이는 표현! 'ほしい(원하다)'와 찰떡궁합!"},{"jp":"彼には困難に立ち向かう勇気がある。","furigana":"かれには こんなんに たちむかう ゆうきが ある。","kr":"그에게는 곤란에 맞설 용기가 있다.","tipEmoji":"💪","tip":"힘든 상황을 마주했을 때, 누군가의 '용기'를 칭찬하거나 이야기할 때 쓰는 멋진 표현! '立ち向かう(맞서다)'와 함께 쓰면 시너지 폭발!"},{"jp":"正直に話す勇気がなかった。","furigana":"しょうじきに はなす ゆうきが ない。","kr":"솔직하게 말할 용기가 없었다.","tipEmoji":"💬","tip":"솔직한 고백이나 어려운 말을 해야 할 때, '勇気がない(용기가 없다)'는 표현으로 자신의 솔직한 마음을 나타낼 수 있어요!"}]}`;

const DEFAULT_PHRASE_PROMPT = `당신은 한국인 학습자를 위한 전문 일본어 강사이자 JLPT 시험 대비 전문가입니다. 인사말, 과도한 친절, 아부성 멘트 등 불필요한 서론/결론은 일절 배제하고, 냉철하고 명쾌하게 핵심만 짚어주는 톤을 유지하세요. 일본어 학습 앱의 "오늘의 표현" 기능에 제공할 JLPT 핵심 문법을 아래 형식을 반드시 지켜서 응답해주세요.

설명이나 부가 텍스트 없이 아래 구분자 형식만 사용하세요.
[랜덤 시드: {seed}]
- 반드시 위 카테고리에 해당하는 JLPT(N4~N3) 필수 문법, 접속어, 또는 문형을 하나 선정할 것.
- 단순히 특이하거나 유행하는 신조어가 아닌, 실제 JLPT 시험 문법 파트에서 자주 출제되는 형태를 제시할 것.
- 이전에 자주 쓰인 극기초 표현은 제외할 것.

===PHRASE===
{"japanese":"[선정된 핵심 문법/접속어]","reading":"[히라가나]","meaning":"[한국어 뜻]","exampleSentence":"[해당 문법이 포함된 전체 일본어 예문]","contextUsage":"[1~2문장 상황 설명]"}

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

[작성 규칙]
- JSON은 반드시 한 줄로. 줄바꿈 없이.
- japanese 키에는 문장 전체가 아닌 '핵심 문법/접속어' 자체만 넣을 것.
- exampleSentence 키에 해당 문법이 사용된 전체 문장을 넣을 것.
- INSIGHT 부분은 반드시 제시된 개조식 포맷(#, ##, ###)을 완벽하게 지켜서 작성할 것.

---
[예시 응답: 〜はずだ 를 선정했을 경우]

===PHRASE===
{"japanese":"〜はずだ","reading":"はずだ","meaning":"~일 것이다, ~할 터이다","exampleSentence":"彼は昨日から徹夜で作業しているから、今日は疲れているはずだ。","contextUsage":"객관적인 근거나 이유를 바탕으로 '틀림없이 그럴 것이다'라고 강하게 확신할 때 사용합니다."}

===INSIGHT===
# 1. 「〜はずだ」의 의미와 특징
## 의미: ~일 것이다, 당연히 ~할 것이다
## 비유: 명탐정 코난이 명확한 증거들을 다 모아놓고 "범인은 틀림없이 너야!"라고 논리적으로 확신하는 느낌. 단순한 '추측'이 아니라, '당연히 그럴 수밖에 없는 이유'가 있을 때 씁니다.
## 뉘앙스와 주의점: 근거 없는 단순한 예감이나 추측일 때는 「〜だろう」나 「〜かもしれない」를 써야 합니다. 「はずだ」는 말하는 사람의 강한 확신(논리적 근거)이 뒷받침되어야 자연스럽습니다.

# 2. 품사별 조립 방법 (접속)
## 동사: 보통형 + はずだ (예: 行く ➔ 行くはずだ)
## い형용사: 보통형 + はずだ (예: 忙しい ➔ 忙しいはずだ)
## な형용사: 어간 + な + はずだ (예: 親切だ ➔ 親切なはずだ)
## 명사: 명사 + の + はずだ (예: 先生 ➔ 先生のはずだ)

# 3. 실전 통문장
## 객관적 상황을 바탕으로 한 확신 (동사 결합)
### 한자: 電車はもうすぐ到着するはずです。
### 히라가나: でんしゃはもうすぐとうちゃくするはずです。
### 한글: 전철은 곧 도착할 것입니다(도착할 게 틀림없습니다).

## 상식적인 기준에 의한 확신 (い형용사 결합)
### 한자: あのレストランはいつも行列ができているから、美味しいはずだ。
### 히라가나: あのれすとらんはいともぎょうれつができているから、おいしいはずだ。
### 한글: 저 식당은 항상 줄을 서 있으니까, 당연히 맛있을 것이다.`;