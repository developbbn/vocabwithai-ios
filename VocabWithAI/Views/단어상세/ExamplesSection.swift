
//
//  ExamplesSection.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  Section 03 — 실전 예문.
//  일본어 원문 + 히라가나 + 한국어 번역 + 꿀팁 박스로 구성된 예문 카드들.
//

import SwiftUI

struct ExamplesSection: View {

    let examples: [Example]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            SectionHeader(
                number: "03",
                emoji: "🎯",
                title: "실전 예문",
                subtitle: "실제 상황에서 이렇게 쓰여요"
            )

            if examples.isEmpty {
                emptyState
            } else {
                VStack(spacing: 14) {
                    ForEach(examples) { example in
                        exampleCard(example)
                    }
                }
            }
        }
    }

    // MARK: - Example Card

    private func exampleCard(_ example: Example) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            // JP 원문 (큰 글씨)
            Text(example.jp)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.themeTextPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // 히라가나 (회색)
            Text(example.furigana)
                .font(.system(size: 13))
                .foregroundColor(.themeTextTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // 한국어 번역
            Text(example.kr)
                .font(.system(size: 14))
                .foregroundColor(.themeTextSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            // 꿀팁 박스
            tipBox(emoji: example.tipEmoji, text: example.tip)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }

    // MARK: - Tip Box

    private func tipBox(emoji: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {

            // 이모지 — 원형 배경
            Text(emoji)
                .font(.system(size: 14))
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(Color.white)
                )

            // 꿀팁 텍스트
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("꿀팁")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeTextPrimary)
                    Text(" · ")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextTertiary)
                    Text(text)
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.small)
                .fill(Color.themeBlueSoft.opacity(0.7))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🌱")
                .font(.system(size: 32))
            Text("실전 예문이 아직 없어요.")
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

struct ExamplesSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ExamplesSection(examples: [
                Example(
                    jp: "新しいことに挑戦する勇気がほしい。",
                    furigana: "あたらしいことに ちょうせんする ゆうきが ほしい。",
                    kr: "새로운 일에 도전할 용기가 필요해.",
                    tipEmoji: "✨",
                    tip: "망설여질 때, 친구를 격려할 때 쓰는 표현. 'ほしい(원하다)'와 찰떡궁합."
                ),
                Example(
                    jp: "彼には困難に立ち向かう勇気がある。",
                    furigana: "かれには こんなんに たちむかう ゆうきが ある。",
                    kr: "그에게는 곤란에 맞설 용기가 있다.",
                    tipEmoji: "💪",
                    tip: "'立ち向かう(맞서다)'와 함께 쓰면 시너지 폭발."
                ),
                Example(
                    jp: "正直に話す勇気がなかった。",
                    furigana: "しょうじきに はなす ゆうきが なかった。",
                    kr: "솔직하게 말할 용기가 없었다.",
                    tipEmoji: "💬",
                    tip: "'勇気がない'는 솔직한 마음을 나타낼 때 자주 쓰여요."
                )
            ])
            .padding()
        }
        .background(Color.themeBackground)
    }
}
