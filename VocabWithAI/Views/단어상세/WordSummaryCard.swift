//
//  WordSummaryCard.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  단어의 핵심 요약 카드.
//  Hero 카드와 KanjiBreakdownSection 사이에 배치되어
//  "이 단어는 결국 이런 뜻이다" 한 줄 스토리를 제공.
//

import SwiftUI

struct WordSummaryCard: View {

    let summary: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            // 전구 이모지 — 원형 흰 배경
            Text("💡")
                .font(.system(size: 18))
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(Color.white)
                )

            // 본문 — 한자를 블루로 강조
            summaryText
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themeTextPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .fill(Color.themeBlueSoft)
        )
    }

    // MARK: - Summary Text with Kanji Highlight

    /// 본문 중 괄호 안 한자 `(勇)`, `(気)` 같은 부분을 블루로 강조.
    /// 괄호 앞의 한자 단어도 함께 블루 처리.
    private var summaryText: Text {
        highlightKanji(in: summary)
    }

    /// 정규식으로 한자(CJK Unified Ideographs)를 찾아 블루로 칠함.
    /// 일본어 단어 설명에서 자연스럽게 한자만 강조됨.
    private func highlightKanji(in text: String) -> Text {
        var result = Text("")
        let kanjiPattern = "[\\p{Han}]+"

        guard let regex = try? NSRegularExpression(pattern: kanjiPattern) else {
            return Text(text)
        }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, options: [], range: range)

        var cursor = 0
        for match in matches {
            let matchRange = match.range

            // 매치 이전 일반 텍스트
            if matchRange.location > cursor {
                let plainRange = NSRange(location: cursor, length: matchRange.location - cursor)
                let plain = nsText.substring(with: plainRange)
                result = result + Text(plain)
            }

            // 한자 부분 블루 강조
            let kanji = nsText.substring(with: matchRange)
            result = result + Text(kanji)
                .foregroundColor(.themeBlue)
                .fontWeight(.bold)

            cursor = matchRange.location + matchRange.length
        }

        // 마지막 꼬리
        if cursor < nsText.length {
            let tailRange = NSRange(location: cursor, length: nsText.length - cursor)
            result = result + Text(nsText.substring(with: tailRange))
        }

        return result
    }
}

// MARK: - Preview

struct WordSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            WordSummaryCard(summary: "내면에서 솟구치는(勇) 뜨거운 마음의 에너지(気)라는 뜻")

            WordSummaryCard(summary: "마음에서 우러나오는 진실된 감정(情)을 누군가에게 알리는(報) 것, 즉 '정보'를 의미해요.")

            WordSummaryCard(summary: "책(本) 그 자체를 의미하는 단어예요.")
        }
        .padding()
        .background(Color.themeBackground)
    }
}
