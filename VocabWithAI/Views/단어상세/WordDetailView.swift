//
//  WordDetailView.swift
//  VocabApp
//
//  Created on 2026-02-03
//  Redesigned on 2026-04-20 — 화이트+블루 테마, 섹션 기반 구조화 뷰.
//

import SwiftUI

struct WordDetailView: View {
    let word: Word
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var repository = WordRepository.shared

    /// Repository에서 최신 word 데이터를 가져옴. 새로고침 후 UI 즉시 반영.
    private var currentWord: Word {
        repository.words.first(where: { $0.id == word.id }) ?? word
    }


    private var isLoading: Bool {
        repository.loadingWordIds.contains(currentWord.id)
    }

    var body: some View {
        VStack {
            customNavBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // 단어 카드 (상단 Hero)
                    WordHeroCard(word: currentWord)
                        .padding(.top, 70)

                    // AI 콘텐츠
                    aiContentArea

                    // 메모
                    if !currentWord.memo.isEmpty {
                        userMemoSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
        .background(Color.themeBackground.ignoresSafeArea())

    }
    

    // MARK: - Nav Bar

    private var customNavBar: some View {
        
        ZStack {
            // 타이틀
            Text("단어 상세")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.themeTextPrimary)
            
            HStack {
                // 뒤로가기
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.themeTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.themeCardBackground)
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                        )
                        .contentShape(Rectangle())
                }

                Spacer()

                    // 새로고침
                    Button(action: {
                        WordRepository.shared.regenerateAIContent(for: currentWord)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isLoading ? .themeTextTertiary : .themeTextPrimary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.themeCardBackground)
                                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                            )
                            .contentShape(Rectangle())
                    }
                    .disabled(isLoading)

                    // 편집
                    NavigationLink(destination: EditWordView(word: currentWord, onDelete: {
                        presentationMode.wrappedValue.dismiss()
                    })) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.themeTextPrimary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.themeCardBackground)
                                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                            )
                            .contentShape(Rectangle())
                    }
            }
        }

    }

    // MARK: - AI Content Area

    /// 분기:
    /// 1) 구조화 디코드 성공 → Summary + 섹션 01/02/03 렌더
    /// 2) 로딩 중 → 스피너
    /// 3) aiContent 있는데 디코드 실패 → 구 마크다운으로 간주, fallback 렌더
    /// 4) aiContent 아예 없음 → 안내 placeholder
    @ViewBuilder
    private var aiContentArea: some View {
        if let content = currentWord.aiContent {
            structuredSections(content)
        } else if isLoading {
            aiLoadingView
        } else {
            noAIContent
        }
    }

    // MARK: AI Content — Structured

    private func structuredSections(_ content: AIContent) -> some View {
        VStack(alignment: .leading, spacing: 36) {

            // Summary 카드 — 있을 때만 렌더. Hero와 Section 01 사이 connective.
            if let summary = content.summary, !summary.isEmpty {
                WordSummaryCard(summary: summary)
            }

            KanjiBreakdownSection(breakdowns: content.kanjiBreakdowns)
            RelatedWordsSection(groups: content.relatedWords)
            ExamplesSection(examples: content.examples)
        }
    }


    // MARK: AI Content — Loading

    private var aiLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("AI 정보를 가져오는 중...")
                .font(.system(size: 14))
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }

    // MARK: AI Content — None

    private var noAIContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.themeTextTertiary.opacity(0.6))
            Text("AI 학습 콘텐츠가 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.themeTextSecondary)
            Text("새로고침 버튼을 눌러 생성해보세요")
                .font(.system(size: 13))
                .foregroundColor(.themeTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }

    // MARK: - User Memo Section

    private var userMemoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                Text("내 메모")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.themeTextPrimary)
            }

            Text(currentWord.memo)
                .font(.system(size: 14))
                .foregroundColor(.themeTextPrimary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.themeCardBackground)
                .cornerRadius(ThemeRadius.large)
                .themeCardShadow()
        }
    }
}

// MARK: - Preview

struct WordDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WordDetailView(word: Word(
                word: "勇気",
                meaning: "용기",
                pronunciation: "ゆうき",
                memo: ""
            ))
        }
    }
}
