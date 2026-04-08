//
//  PhraseDetailView.swift
//  VocabWithAI
//
//  Created on 2026-03-30
//
//  DailyPhraseView를 대체. 두 가지 모드로 동작:
//  1. phrase == nil  → 오늘의 표현 로드 (HomeView 진입)
//  2. phrase != nil  → 전달받은 표현 표시 (검색/서재 진입)
//

import SwiftUI

struct PhraseDetailView: View {

    /// 외부에서 표현을 넘길 때 사용. nil이면 오늘의 표현 모드
    var phrase: DailyPhrase? = nil

    @ObservedObject private var viewModel = DailyPhraseViewModel.shared
    @Environment(\.presentationMode) private var presentationMode

    // 현재 표시할 표현 — 외부 phrase 우선, 없으면 viewModel.currentPhrase
    private var displayPhrase: DailyPhrase? {
        phrase ?? viewModel.currentPhrase
    }

    // 오늘의 표현 모드 여부
    private var isTodayMode: Bool { phrase == nil }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            // 상태 분기
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
                .padding(.horizontal, 20)
                .padding(.top, 12)
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

    // MARK: - Custom Nav Bar

    private var customNavBar: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(12)
                    .contentShape(Rectangle())
            }
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5)
            Text("오늘의 표현을 가져오는 중...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Button(action: { viewModel.generateTodayPhrase() }) {
                Text("다시 시도")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    // MARK: - Content View

    private func contentView(phrase: DailyPhrase) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Date Header + 새로고침 (오늘의 표현 모드일 때만)
                dateHeader(phrase: phrase)
                    .padding(.top, 80)

                // 타이틀
                Text(isTodayMode ? "오늘의 표현" : "표현 상세")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)

                // 표현 카드
                phraseCard(phrase: phrase)

                // AI Insight
                if let aiInsight = phrase.aiInsight, !aiInsight.isEmpty {
                    aiInsightSection(content: aiInsight)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Date Header

    private func dateHeader(phrase: DailyPhrase) -> some View {
        HStack {
            Text(phrase.dateString)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
            Spacer()
            // 새로고침 — 오늘의 표현 모드에서만 표시
            if isTodayMode {
                Button(action: {
                    viewModel.currentPhrase = nil
                    viewModel.generateTodayPhrase()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Phrase Card

    private func phraseCard(phrase: DailyPhrase) -> some View {
        VStack(spacing: 0) {
            // 카드 헤더
            HStack {
                // 북마크 — 오늘의 표현 모드에서만 토글 가능
                Button(action: {
                    if isTodayMode { viewModel.toggleBookmark() }
                }) {
                    Image(systemName: phrase.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24))
                        .foregroundColor(phrase.isBookmarked ? .blue : .gray.opacity(0.4))
                }
                .disabled(!isTodayMode)

                Spacer()

                Text("PHRASE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // 메인 콘텐츠
            VStack(spacing: 16) {
                Text(phrase.reading)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)

                Text(phrase.japanese)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Divider()
                    .frame(width: 60)
                    .padding(.vertical, 8)

                Text(phrase.meaning)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Text(phrase.contextUsage)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }

    // MARK: - AI Insight Section

    private func aiInsightSection(content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("AI Insight")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }

            MarkdownContentView(content: content)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview
struct PhraseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // 오늘의 표현 모드
        NavigationStack {
            PhraseDetailView()
        }
        .previewDisplayName("오늘의 표현 모드")

        // 특정 표현 모드
        NavigationStack {
            PhraseDetailView(phrase: DailyPhrase(
                japanese: "〜にしては",
                reading: "にしては",
                meaning: "~치고는, ~인 것에 비해서",
                exampleSentence: "彼は新人にしては、仕事が早い。",
                contextUsage: "기대와 다른 결과를 나타낼 때 사용",
                aiInsight: "## 의미\n기대와 다른 결과\n## 예문\n- 彼は新人にしては仕事が早い。"
            ))
        }
        .previewDisplayName("특정 표현 모드")
    }
}
