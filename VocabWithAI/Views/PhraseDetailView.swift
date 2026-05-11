//
//  PhraseDetailView.swift
//  VocabWithAI
//
//  Created on 2026-03-30
//  Redesigned on 2026-05-07
//

import SwiftUI

// ============================================================
// MARK: - Main View
// ============================================================

struct PhraseDetailView: View {

    var phrase: DailyPhrase? = nil

    @ObservedObject private var viewModel = DailyPhraseViewModel.shared
    @Environment(\.presentationMode) private var presentationMode

    private var displayPhrase: DailyPhrase? { phrase ?? viewModel.currentPhrase }
    private var isTodayMode: Bool { phrase == nil }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if let p = displayPhrase {
                contentView(phrase: p)
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            }
        }
        .overlay(alignment: .top) {
            customNavBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
        .onAppear {
            guard isTodayMode else { return }
            DailyStatsManager.shared.markExpressionDone()
            if viewModel.currentPhrase == nil && !viewModel.isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.generateTodayPhrase()
                }
            }
        }
    }

    // MARK: Nav Bar

    private var customNavBar: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text("문법 표현")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)

            Spacer()

            HStack(spacing: 0) {
                if isTodayMode {
                    Button(action: {
                        viewModel.currentPhrase = nil
                        viewModel.generateTodayPhrase()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                    }
                }
                if isTodayMode, let p = displayPhrase {
                    Button(action: { viewModel.toggleBookmark() }) {
                        Image(systemName: p.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(p.isBookmarked ? .blue : .black)
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
    }

    // MARK: Loading / Error

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("오늘의 표현을 가져오는 중...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button(action: { viewModel.generateTodayPhrase() }) {
                Text("다시 시도")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    // MARK: Main Content

    private func contentView(phrase: DailyPhrase) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 60)

                PhraseGrammarHeader(phrase: phrase)

                PhraseSampleCard(
                    japanese: phrase.exampleSentence,
                    furigana: phrase.exampleFurigana ?? "",
                    korean: phrase.exampleKorean ?? phrase.meaning,
                    highlightWord: phrase.japanese
                )

                if let aiInsight = phrase.aiInsight, !aiInsight.isEmpty {
                    let parsed = PhraseInsightParser.parse(aiInsight, mainGrammar: phrase.japanese)

                    InsightMeaningSection(parsed: parsed)

                    if !parsed.connections.isEmpty {
                        InsightConnectionSection(connections: parsed.connections)
                    }

                    if !parsed.practiceSentences.isEmpty {
                        InsightPracticeSection(sentences: parsed.practiceSentences)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
    }
}

// ============================================================
// MARK: - 그래머 헤더 카드
// ============================================================

struct PhraseGrammarHeader: View {
    let phrase: DailyPhrase

    private let purpleColor = Color(red: 0.40, green: 0.30, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // GRAMMAR 뱃지
            HStack(spacing: 6) {
                Text("文")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(purpleColor)
                    .frame(width: 18, height: 18)
                    .background(Color.white)
                    .clipShape(Circle())
                Text("GRAMMAR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(purpleColor)
            .clipShape(Capsule())

            // 핵심 문법
            Text(phrase.japanese)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 4)

            // 히라가나
            Text(phrase.reading)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.blue)

            // 한국어 의미
            Text(phrase.meaning)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.black)

            // 컨텍스트 박스
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.blue)
                    .padding(.top, 1)
                Text(phrase.contextUsage)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.75))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// ============================================================
// MARK: - 대표 예문 카드 (검은 배경)
// ============================================================

struct PhraseSampleCard: View {
    let japanese: String
    let furigana: String
    let korean: String
    let highlightWord: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 상단: 인용 점 + 라벨
            HStack(alignment: .top) {
                Text("\u{201C}\u{201C}")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white.opacity(0.4))
                    .offset(y: -4)
                Spacer()
                Text("대표 예문")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.5)
            }

            // 일본어 (highlightWord만 노랗게)
            Text(highlightedDarkText(japanese, highlight: highlightWord))
                .font(.system(size: 22, weight: .bold))
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 히라가나 (있을 때만)
            if !furigana.isEmpty {
                Text(furigana)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .lineSpacing(3)
            }

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)

            // 한국어
            Text(korean)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.10, green: 0.13, blue: 0.20))
        .cornerRadius(20)
    }

    private func highlightedDarkText(_ japanese: String, highlight: String) -> AttributedString {
        var attr = AttributedString(japanese)
        attr.foregroundColor = .white

        let cleanWord = highlight
            .replacingOccurrences(of: "〜", with: "")
            .replacingOccurrences(of: "~", with: "")

        if !cleanWord.isEmpty, let range = attr.range(of: cleanWord) {
            attr[range].foregroundColor = Color.yellow
        }
        return attr
    }
}

// ============================================================
// MARK: - 섹션 헤더 (재사용)
// ============================================================

struct InsightSectionHeader: View {
    let icon: String
    let title: String
    let number: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            HStack(spacing: 8) {
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 8)
    }
}

// ============================================================
// MARK: - Section 01: 의미와 특징
// ============================================================

struct InsightMeaningSection: View {
    let parsed: ParsedInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightSectionHeader(
                icon: "📒",
                title: "의미와 특징",
                number: "01",
                subtitle: "감 잡히게 풀어드릴게요"
            )

            if !parsed.meaning.isEmpty {
                InsightSubCard(title: "의미", content: parsed.meaning, accentColor: nil)
            }

            if !parsed.analogy.isEmpty {
                InsightSubCard(title: "비유", content: parsed.analogy, accentColor: .blue)
            }

            if !parsed.nuance.isEmpty {
                InsightSubCard(title: "뉘앙스", content: parsed.nuance, accentColor: nil)
            }

            if let warning = parsed.warning {
                InsightWarningBox(content: warning)
            }
        }
    }
}

struct InsightSubCard: View {
    let title: String
    let content: String
    let accentColor: Color?

    var body: some View {
        HStack(spacing: 0) {
            if let accent = accentColor {
                Rectangle()
                    .fill(accent)
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)

                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.85))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct InsightWarningBox: View {
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .padding(.top, 2)
            Text(content)
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.orange.opacity(0.10))
        .cornerRadius(10)
    }
}

// ============================================================
// MARK: - Section 02: 접속 방법
// ============================================================

struct InsightConnectionSection: View {
    let connections: [GrammarConnection]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightSectionHeader(
                icon: "🧩",
                title: "접속 방법",
                number: "02",
                subtitle: "이렇게 붙여서 만들어요"
            )

            ForEach(connections) { conn in
                InsightConnectionCard(connection: conn)
            }
        }
    }
}

struct InsightConnectionCard: View {
    let connection: GrammarConnection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(connection.partOfSpeech)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                Text(connection.formula)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
            }

            if !connection.examples.isEmpty {
                VStack(spacing: 6) {
                    ForEach(connection.examples) { ex in
                        HStack {
                            Text(ex.from)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black.opacity(0.7))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13))
                                .foregroundColor(.blue.opacity(0.6))
                            Spacer()
                            Text(ex.to)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

// ============================================================
// MARK: - Section 03: 실전 통문장
// ============================================================

struct InsightPracticeSection: View {
    let sentences: [PracticeSentence]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightSectionHeader(
                icon: "🎯",
                title: "실전 통문장",
                number: "03",
                subtitle: "실제 상황에서 이렇게 쓰여요"
            )

            ForEach(Array(sentences.enumerated()), id: \.element.id) { index, sentence in
                InsightPracticeCard(number: index + 1, sentence: sentence)
            }
        }
    }
}

struct InsightPracticeCard: View {
    let number: Int
    let sentence: PracticeSentence

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(sentence.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                Spacer()
            }

            Text(sentence.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))

            Text(highlightedLightText(sentence.japanese, highlight: sentence.highlightWord))
                .font(.system(size: 19, weight: .bold))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(sentence.furigana)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .lineSpacing(3)

            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 2)

            Text(sentence.korean)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    private func highlightedLightText(_ japanese: String, highlight: String) -> AttributedString {
        var attr = AttributedString(japanese)
        attr.foregroundColor = .black

        let cleanWord = highlight
            .replacingOccurrences(of: "〜", with: "")
            .replacingOccurrences(of: "~", with: "")

        if !cleanWord.isEmpty, let range = attr.range(of: cleanWord) {
            attr[range].backgroundColor = Color.yellow.opacity(0.45)
            attr[range].foregroundColor = Color.blue
        }
        return attr
    }
}

// ============================================================
// MARK: - Preview
// ============================================================

struct PhraseDetailView_Previews: PreviewProvider {
    static let sampleInsight = """
    # 1. 「〜次第」의 의미와 특징
    ## 의미: ~하는 대로, ~하자마자
    ## 비유: 스위치를 누르면 불이 즉시 켜지는 것처럼, 어떤 일이 끝나면 지체 없이 다음 행동이 이어지는 상황. 완료 후 즉시 행동을 강조.
    ## 뉘앙스와 주의점: 주로 동사의 ます형에 접속하여 '어떤 일이 완료되면 바로 다음 행동을 한다'는 의미로 사용.
    *명사에 접속하는 「〜次第」는 '〜에 따라, ~에 달려 있다'는 다른 의미를 가지므로 혼동에 주의.

    # 2. 품사별 조립 방법 (접속)
    ## 동사: ます형 + 次第 (예: できます ➔ でき次第, 終わります ➔ 終わり次第)

    # 3. 실전 통문장
    ## 업무 상황에서의 즉시 보고 (동사 결합)
    ### 한자: 資料がまとまり次第、会議を始めます。
    ### 히라가나: しりょうがまとまりしだい、かいぎをはじまります。
    ### 한글: 자료가 정리되는 대로, 회의를 시작하겠습니다.

    ## 서비스 제공 시의 즉시 안내 (동사 결합)
    ### 한자: 商品が届き次第、お客様にご連絡いたします。
    ### 히라가나: しょうひんがとどきしだい、おきゃくさまにごれんらくいたします。
    ### 한글: 상품이 도착하는 대로, 고객님께 연락드리겠습니다.
    """

    static var previews: some View {
        NavigationStack {
            PhraseDetailView(phrase: DailyPhrase(
                japanese: "〜次第",
                reading: "しだい",
                meaning: "~하는 대로, ~하자마자",
                exampleSentence: "会議の準備ができ次第、ご連絡いたします。",
                exampleFurigana: "かいぎのじゅんびができしだい、ごれんらくいたします。",
                exampleKorean: "회의 준비가 되는 대로, 연락드리겠습니다.",
                contextUsage: "특정 동작이나 상황이 완료되는 즉시, 다음 행동을 하겠다고 전달할 때 사용합니다. 주로 공적인 상황에서 사용됩니다.",
                aiInsight: sampleInsight
            ))
        }
        .previewDisplayName("새 디자인")
    }
}
