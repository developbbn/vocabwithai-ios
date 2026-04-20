//
//  WordHeroCard.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  WordDetailView 상단 단어 카드.
//  WORD 배지 + 큰 한자 + 히라가나(블루) + 한국어 뜻.
//

import SwiftUI

struct WordHeroCard: View {

    let word: Word

    var body: some View {
        VStack(spacing: 0) {

            // 상단: WORD 배지 (좌측 정렬)
            HStack {
                wordBadge
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // 메인 콘텐츠
            VStack(spacing: 12) {

                // 단어 (큰 한자)
                Text(word.word)
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(.themeTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // 히라가나 — 블루
                if !word.pronunciation.isEmpty {
                    Text(word.pronunciation)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.themeBlue)
                }

                // 뜻
                Text(word.meaning)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.themeTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }

    // MARK: - WORD Badge

    /// PDF의 "🀄 WORD" 블루 알약 배지.
    private var wordBadge: some View {
        HStack(spacing: 6) {
            Text("🀄")
                .font(.system(size: 11))
            Text("WORD")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color.themeBlue)
        )
    }
}

// MARK: - Preview

struct WordHeroCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WordHeroCard(word: Word(
                word: "勇気",
                meaning: "용기",
                pronunciation: "ゆうき",
                memo: ""
            ))
            .padding()

            WordHeroCard(word: Word(
                word: "図書館",
                meaning: "도서관",
                pronunciation: "としょかん",
                memo: ""
            ))
            .padding()
        }
        .background(Color.themeBackground)
    }
}
