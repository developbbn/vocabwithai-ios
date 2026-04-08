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
            VStack(alignment: .leading, spacing: 28) {
                wordHeader
                    .padding(.top, 80)

                if let aiContent = currentWord.aiContent, !aiContent.isEmpty {
                    aiContentView(aiContent)
                } else if repository.loadingWordIds.contains(currentWord.id) {
                    aiLoadingView
                } else {
                    noAIContent
                }

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

    private var wordHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentWord.word)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.black)

            if !currentWord.pronunciation.isEmpty {
                Text(currentWord.pronunciation)
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }

            Text(currentWord.meaning)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private func aiContentView(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("AI Learning")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }

            if #available(iOS 15.0, *) {
                Text(.init(content))
                    .font(.system(size: 16))
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
            } else {
                Text(content)
                    .font(.system(size: 16))
                    .lineSpacing(6)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
            }
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
