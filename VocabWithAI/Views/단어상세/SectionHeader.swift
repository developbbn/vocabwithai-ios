
//
//  SectionHeader.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  WordDetailView의 섹션 01/02/03 공통 헤더.
//  원형 번호 배지 + 이모지 + 타이틀 + 서브타이틀 구성.
//

import SwiftUI

struct SectionHeader: View {

    /// 섹션 번호. "01", "02", "03".
    let number: String

    /// 섹션을 대표하는 이모지. 예: "🦴", "🍠", "🎯"
    let emoji: String

    /// 섹션 타이틀. 예: "한자 나노 분해"
    let title: String

    /// 섹션 서브타이틀 (캡션). 예: "한 글자씩 뼈대부터 스토리까지"
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // 상단: 번호 배지 + 이모지 + 타이틀
            HStack(spacing: 10) {

                // 원형 번호 배지
                Text(number)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(SectionBadgeStyle.foreground)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(SectionBadgeStyle.background)
                    )

                // 이모지
                Text(emoji)
                    .font(.system(size: 18))

                // 타이틀
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
            }

            // 서브타이틀 — 배지 폭(28) + spacing(10) 만큼 들여쓰기해서
            // 이모지 아래 라인과 시각적으로 맞춤
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.themeTextTertiary)
                .padding(.leading, 38)
        }
    }
}

// MARK: - Preview

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 32) {
            SectionHeader(number: "01", emoji: "🦴",
                          title: "한자 나노 분해",
                          subtitle: "한 글자씩 뼈대부터 스토리까지")
            SectionHeader(number: "02", emoji: "🍠",
                          title: "관련 단어",
                          subtitle: "고구마 줄기처럼 딸려 나오는 파생 단어")
            SectionHeader(number: "03", emoji: "🎯",
                          title: "실전 예문",
                          subtitle: "실제 상황에서 이렇게 쓰여요")
        }
        .padding()
        .background(Color.themeBackground)
    }
}
