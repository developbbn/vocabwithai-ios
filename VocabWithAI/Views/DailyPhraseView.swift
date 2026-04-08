//
//  DailyPhraseView.swift
//  VocabApp
//
//  Created on 2026-02-04
//

import SwiftUI

struct DailyPhraseView: View {
    @ObservedObject private var viewModel = DailyPhraseViewModel.shared
    @Environment(\.dismiss) private var dismiss

    // 검색에서 특정 표현을 넘길 때 사용. nil이면 오늘의 표현 로드
    var phrase: DailyPhrase? = nil

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if let fixedPhrase = phrase {
                // 외부에서 표현을 받은 경우 → 바로 표시
                contentView(phrase: fixedPhrase)
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if let phrase = viewModel.currentPhrase {
                contentView(phrase: phrase)
            }
            
            // Custom Nav Bar
            VStack {
                customNavBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard phrase == nil else { return } // 외부 표현이 있으면 스킵

            // 표현 학습 완료 처리
            DailyStatsManager.shared.markExpressionDone()

            // 이미 로드되어 있으면 즉시 표시, 없으면 로드
            if viewModel.currentPhrase == nil && !viewModel.isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.generateTodayPhrase()
                }
            }
        }
    }
    
    // MARK: - Custom Nav Bar
    private var customNavBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            Spacer()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
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
                // Date Header
                dateHeader(phrase: phrase)
                    .padding(.top, 80)
                
                // Title
                Text("오늘의 표현")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                // Main Phrase Card
                phraseCard(phrase: phrase)
                
                // AI Insight Section
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

            if self.phrase == nil {
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
            // Card Header (북마크 + 태그)
            HStack {
                // Bookmark Button
                Button(action: { viewModel.toggleBookmark() }) {
                    Image(systemName: phrase.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24))
                        .foregroundColor(phrase.isBookmarked ? .blue : .gray.opacity(0.4))
                }
                
                Spacer()
                
                // Tag
                Text("DAILY PHRASE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Main Content
            VStack(spacing: 16) {
                // Reading (히라가나)
                Text(phrase.reading)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                // Japanese (큰 글씨)
                Text(phrase.japanese)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Divider()
                    .frame(width: 60)
                    .padding(.vertical, 8)
                
                // Meaning (한국어 뜻)
                Text(phrase.meaning)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                // Context Usage
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
struct DailyPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        DailyPhraseView()
    }
}
