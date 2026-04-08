//
//  WordDetailView.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import SwiftUI

struct WordDetailView: View {
    let word: Word
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var repository = WordRepository.shared

    /// Repository에서 최신 word 데이터를 가져옴. 새로고침 후 UI 즉시 반영
    private var currentWord: Word {
        repository.words.first(where: { $0.id == word.id }) ?? word
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 타이틀
                Text("단어 상세")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 80)

                // 단어 카드
                wordCard

                // AI 콘텐츠
                if let aiContent = currentWord.aiContent, !aiContent.isEmpty {
                    aiContentSection(aiContent)
                } else if repository.loadingWordIds.contains(currentWord.id) {
                    aiLoadingView
                } else {
                    noAIContent
                }

                // 메모
                if !currentWord.memo.isEmpty {
                    userMemoSection
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            customNavBar
                .padding(.horizontal, 20)
                .padding(.top, 12)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Word Card
    private var wordCard: some View {
        VStack(spacing: 0) {
            // 카드 헤더 — 태그
            HStack {
                Spacer()
                Text("WORD")
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
                // 발음 (히라가나)
                if !currentWord.pronunciation.isEmpty {
                    Text(currentWord.pronunciation)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }

                // 단어 (큰 글씨)
                Text(currentWord.word)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Divider()
                    .frame(width: 60)
                    .padding(.vertical, 4)

                // 뜻
                Text(currentWord.meaning)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }

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

            // 새로고침 버튼 — AI 콘텐츠 재생성
            Button(action: {
                WordRepository.shared.regenerateAIContent(for: currentWord)
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(repository.loadingWordIds.contains(currentWord.id) ? .gray : .black)
                    .padding(12)
                    .contentShape(Rectangle())
            }
            .disabled(repository.loadingWordIds.contains(currentWord.id))

            NavigationLink(destination: EditWordView(word: currentWord, onDelete: {
                presentationMode.wrappedValue.dismiss()
            })) {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(12)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - AI Content Section
    private func aiContentSection(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("AI Learning")
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

    private var aiLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("AI 정보를 가져오는 중...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var noAIContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            Text("AI 학습 콘텐츠가 없습니다")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Text("단어 등록 시 AI가 자동으로 분석합니다")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var userMemoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                Text("내 메모")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }

            Text(currentWord.memo)
                .font(.system(size: 16))
                .lineSpacing(6)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview
struct WordDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WordDetailView(word: Word(
                word: "検索",
                meaning: "검색",
                pronunciation: "けんさく",
                memo: ""
            ))
        }
    }
}
