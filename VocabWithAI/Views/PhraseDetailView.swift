//
//  PhraseDetailView.swift
//  VocabWithAI
//
//  Created on 2026-03-30
//

import SwiftUI

struct PhraseDetailView: View {
    let phrase: DailyPhrase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Date Header
                Text(phrase.dateString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.top, 80)

                // Title
                Text("표현 상세")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)

                // Main Phrase Card
                phraseCard

                // AI Insight Section
                if let aiInsight = phrase.aiInsight, !aiInsight.isEmpty {
                    aiInsightSection(content: aiInsight)
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

    // MARK: - Phrase Card
    private var phraseCard: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                Image(systemName: phrase.isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 24))
                    .foregroundColor(phrase.isBookmarked ? .blue : .gray.opacity(0.4))

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

            // Main Content
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

            if #available(iOS 15.0, *) {
                Text(.init(content))
                    .font(.system(size: 16))
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(16)
            } else {
                Text(content)
                    .font(.system(size: 16))
                    .lineSpacing(6)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(16)
            }
        }
    }
}
