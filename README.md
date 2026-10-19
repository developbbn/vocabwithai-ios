# 단어칩 📚

AI가 만들어주는 일본어 단어장
단어 하나만 입력하면 한자 분해·암기 스토리·예문·관련어·자동 퀴즈까지 한 번에

# 📱 스크린샷

![홈, 단어 상세, 한자 분해](<img width="2400" height="1634" alt="main" src="https://github.com/user-attachments/assets/258ac970-9fa7-49b7-a822-402eca6c0d8a" />

![퀴즈: 정답, 오답, 중단 팝업, 결과](<img width="2400" height="1229" alt="quiz" src="https://github.com/user-attachments/assets/c1eabc38-ffb8-46f6-ba24-05be75150526" />

# 🌱 왜 만들었나
JLPT N3를 준비하면서 단어 하나를 외우는 데에 사전 탭, 한자 어원 탭, 예문 검색 탭이 따로 열려있는 게 비효율적이었습니다.
"단어 하나만 던지면 학습에 필요한 모든 걸 AI가 정리해주면 어떨까?"
이 질문에서 출발해서, 한자 분해·시각적 암기 스토리·실전 예문·자동 퀴즈까지 한 화면에서 끝나는 단어장 앱을 만들었습니다.

# ✨ 주요 기능
## 🧠 AI 단어 학습 콘텐츠 생성
단어 하나만 입력하면 Gemini가 학습에 필요한 정보를 한 번에 생성합니다:

- 한자 분해 — 한자별 음독/훈독, 부수, 구성요소, 진짜 어원, 그리고 시각적으로 외우기 쉬운 암기 스토리
- 관련어 — 같은 한자가 쓰인 단어들과 짧은 예문
- 실전 예문 3개 — 직역체가 아닌, 일본 현지에서 실제로 쓰이는 자연스러운 문장 + 활용 팁

## 🎯 자동 4지선다 퀴즈
등록한 단어로 히라가나 읽기·한자 표기 퀴즈가 자동 생성됩니다. 단순 무작위가 아니라 헷갈리기 쉬운 유사 발음·유사 한자를 오답 선지로 골라 학습 효과를 높였습니다.
퀴즈를 중간에 종료해도 지금까지 푼 문제로 결과가 집계되고, 틀린 문제를 바로 다시 확인할 수 있습니다.

## 🔥 오늘의 학습 기록
홈 화면에서 오늘 등록한 단어 수와 푼 퀴즈 수를 매일 확인할 수 있습니다.

## 🔍 검색
저장한 단어를 검색할 수 있습니다.

# 🛠 기술 스택
## iOS

- Swift · SwiftUI · Combine · MVVM
- Firebase iOS SDK (Auth · Firestore · Functions)

## Backend

- Firebase Cloud Functions (TypeScript, v2 onCall)
- Firestore — 사용자 데이터 + 일일 사용량 카운터
- Google Gemini API — gemini-2.5-flash (primary) · gemini-2.0-flash (fallback)

# 🏗 아키텍처
```
┌─────────────────┐   HTTPS   ┌────────────────────┐   HTTPS   ┌──────────────┐
│   iOS Client    │  + Auth   │  Cloud Functions   │  + Key    │  Gemini API  │
│ SwiftUI+Combine │ ────────▶ │ (TypeScript · v2)  │ ────────▶ │              │
└─────────────────┘   Token   └────────┬───────────┘  (Secret  └──────────────┘
                                       │              Manager)
                                       ▼
                              ┌────────────────┐
                              │   Firestore    │
                              │ users / usage  │
                              └────────────────┘
```
