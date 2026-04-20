
//
//  RelatedWordsSection.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  Section 02 — 관련 단어.
//  단어를 구성하는 한자별로 그룹핑해서 파생 단어들을 보여줌.
//

import SwiftUI

struct RelatedWordsSection: View {

    let groups: [RelatedWordGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            SectionHeader(
                number: "02",
                emoji: "🍠",
                title: "관련 단어",
                subtitle: "고구마 줄기처럼 딸려 나오는 파생 단어"
            )

            if groups.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    ForEach(groups) { group in
                        groupCard(group)
                    }
                }
            }
        }
    }

    // MARK: - Group Card

    /// 한 한자 그룹의 카드. 헤더(한자 타일 + 타이틀) + 단어 리스트.
    private func groupCard(_ group: RelatedWordGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // 그룹 헤더
            groupHeader(sourceKanji: group.sourceKanji)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // 단어 행들
            VStack(spacing: 0) {
                ForEach(Array(group.words.enumerated()), id: \.element.id) { index, word in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    wordRow(word)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }

    // MARK: - Group Header

    private func groupHeader(sourceKanji: String) -> some View {
        HStack(spacing: 12) {
            // 한자 블루 타일
            Text(sourceKanji)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.themeBlue)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: ThemeRadius.small)
                        .fill(Color.themeBlueSoft)
                )

            Text("\(sourceKanji)에서 뻗어난 단어")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.themeTextPrimary)
        }
    }

    // MARK: - Word Row

    /// 한 단어 행.
    /// 상단 라인: 한자 + 후리가나 (블루) + 우측 한국어 뜻
    /// 하단 박스: 예문 JP + 예문 KR
    private func wordRow(_ word: RelatedWord) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.kanji)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.themeTextPrimary)

                Text(word.reading)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.themeBlue)

                Spacer(minLength: 8)

                Text(word.meaning)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.trailing)
            }

            // 예문 박스
            VStack(alignment: .leading, spacing: 4) {
                Text(word.exampleJP)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.themeTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(word.exampleKR)
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.small)
                    .fill(Color.themeBlueSoft.opacity(0.6))
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🌱")
                .font(.system(size: 32))
            Text("관련 단어가 아직 없어요.")
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }
}

// MARK: - Preview

struct RelatedWordsSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            RelatedWordsSection(groups: [
                RelatedWordGroup(
                    sourceKanji: "勇",
                    words: [
                        RelatedWord(
                            kanji: "勇者",
                            reading: "ゆうしゃ",
                            meaning: "용사",
                            exampleJP: "勇者が魔王を倒した。",
                            exampleKR: "용사가 마왕을 쓰러뜨렸다."
                        ),
                        RelatedWord(
                            kanji: "勇敢",
                            reading: "ゆうかん",
                            meaning: "용감",
                            exampleJP: "勇敢な行動",
                            exampleKR: "용감한 행동"
                        )
                    ]
                ),
                RelatedWordGroup(
                    sourceKanji: "気",
                    words: [
                        RelatedWord(
                            kanji: "元気",
                            reading: "げんき",
                            meaning: "건강, 활기",
                            exampleJP: "お元気ですか。",
                            exampleKR: "잘 지내세요?"
                        ),
                        RelatedWord(
                            kanji: "天気",
                            reading: "てんき",
                            meaning: "날씨",
                            exampleJP: "明日の天気は晴れだ。",
                            exampleKR: "내일 날씨는 맑음이다."
                        )
                    ]
                )
            ])
            .padding()
        }
        .background(Color.themeBackground)
    }
}
