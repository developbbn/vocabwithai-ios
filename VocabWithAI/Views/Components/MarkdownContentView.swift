//
//  MarkdownContentView.swift
//  VocabWithAI
//
//  Created on 2026-04-08
//
//  Text(.init()) 은 #헤더를 지원하지 않아서
//  줄 단위로 직접 파싱해 SwiftUI View로 렌더링한다.
//

import SwiftUI

/// 마크다운 텍스트를 줄 단위로 파싱해 SwiftUI View로 렌더링하는 컴포넌트.
/// 지원 문법:
/// - # H1, ## H2, ### H3 헤더
/// - - 또는 * 로 시작하는 불릿 리스트
/// - **bold** 인라인 강조
/// - 빈 줄은 간격으로 처리
struct MarkdownContentView: View {

    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                lineView(for: line)
            }
        }
    }

    // MARK: - Parsing

    private var lines: [String] {
        content.components(separatedBy: "\n")
    }

    @ViewBuilder
    private func lineView(for line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            Spacer().frame(height: 6)

        } else if trimmed.hasPrefix("### ") {
            // H3 - 작은 세미볼드
            Text(trimmed.dropFirst(4))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 2)

        } else if trimmed.hasPrefix("## ") {
            // H2 - 중간 볼드
            Text(trimmed.dropFirst(3))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 6)

        } else if trimmed.hasPrefix("# ") {
            // H1 - 큰 볼드 + 구분선
            VStack(alignment: .leading, spacing: 4) {
                Text(trimmed.dropFirst(2))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Divider()
            }
            .padding(.top, 10)

        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            // 불릿 리스트
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(width: 10)
                inlineText(String(trimmed.dropFirst(2)))
                    .font(.system(size: 15))
                    .fixedSize(horizontal: false, vertical: true)
            }

        } else {
            // 일반 텍스트 (인라인 bold 지원)
            inlineText(trimmed)
                .font(.system(size: 15))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Inline Bold Parser

    /// **text** 패턴을 bold로 렌더링
    private func inlineText(_ str: String) -> Text {
        var result = Text("")
        var remaining = str

        while !remaining.isEmpty {
            if let boldStart = remaining.range(of: "**"),
               let boldEnd = remaining.range(of: "**", range: boldStart.upperBound..<remaining.endIndex) {
                let before = String(remaining[remaining.startIndex..<boldStart.lowerBound])
                if !before.isEmpty { result = result + Text(before) }

                let bold = String(remaining[boldStart.upperBound..<boldEnd.lowerBound])
                result = result + Text(bold).bold()

                remaining = String(remaining[boldEnd.upperBound...])
            } else {
                result = result + Text(remaining)
                break
            }
        }
        return result
    }
}

// MARK: - Preview
struct MarkdownContentView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MarkdownContentView(content: """
            # 1. 한자 분석
            ## 意味: 의미
            이 문법은 **~にしては** 형태로 사용됩니다.
            ## 특징:
            - 기대와 다른 결과를 나타냄
            - N3~N2 수준
            ### 한자: 彼は新人にしては仕事が早い。
            ### 히라가나: かれはしんじんにしてはしごとがはやい。
            ### 한글: 그는 신인치고는 일이 빠르다.
            """)
            .padding()
        }
    }
}
