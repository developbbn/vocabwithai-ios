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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                wordHeader
                    .padding(.top, 80)

                if let aiContent = word.aiContent, !aiContent.isEmpty {
                    aiContentView(aiContent)
                } else {
                    noAIContent
                }

                if !word.memo.isEmpty {
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
        }
    }

    private var wordHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word.word)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.black)

            if !word.pronunciation.isEmpty {
                Text(word.pronunciation)
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }

            Text(word.meaning)
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

            Text(word.memo)
                .font(.system(size: 16))
                .lineSpacing(6)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(16)
        }
    }
}
