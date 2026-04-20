
//
//  KanjiBreakdownSection.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  Section 01 — 한자 나노 분해.
//  Kanji 탭 셀렉터 + 선택된 한자의 상세 카드 (뼈대/모양 분해/FACT/MSG).
//

import SwiftUI

struct KanjiBreakdownSection: View {

    let breakdowns: [KanjiBreakdown]

    /// 현재 선택된 한자 인덱스. 상위에서 바인딩 받아도 되지만
    /// 섹션 내부 로컬 상태로 충분.
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            SectionHeader(
                number: "01",
                emoji: "🦴",
                title: "한자 나노 분해",
                subtitle: "한 글자씩 뼈대부터 스토리까지"
            )

            if breakdowns.isEmpty {
                // 순수 히라가나/가타카나 단어 케이스
                emptyState
            } else {
                tabSelector
                detailCard(for: breakdowns[safe: selectedIndex] ?? breakdowns[0])
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 10) {
            ForEach(Array(breakdowns.enumerated()), id: \.offset) { index, item in
                kanjiTab(
                    kanji: item.kanji,
                    meaning: item.meaning,
                    index: index + 1,
                    isSelected: index == selectedIndex
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = index
                    }
                }
            }
        }
    }

    private func kanjiTab(kanji: String, meaning: String, index: Int, isSelected: Bool) -> some View {
        // 뜻이 길 수 있으니 첫 번째 조각만 탭 라벨로 사용 (예: "날랠 용 / 용감할 용" → "날랠 용")
        let shortMeaning = meaning
            .split(separator: "/").first
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? meaning

        return HStack(spacing: 12) {
            // 한자 대형
            Text(kanji)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(isSelected ? .white : .themeTextPrimary)

            // 우측 정보
            VStack(alignment: .leading, spacing: 2) {
                Text("KANJI \(index)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(isSelected ? Color.white.opacity(0.7) : .themeTextTertiary)
                Text(shortMeaning)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .themeTextPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.medium)
                .fill(isSelected ? Color.themeDeepNavy : Color.themeBlueSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.medium)
                .stroke(isSelected ? Color.clear : Color.themeBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Detail Card

    private func detailCard(for breakdown: KanjiBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 20) {

            // 상단 — 한자 타일 + 훈/뜻 + 부수 pill
            detailHeader(for: breakdown)

            // 구분선
            Divider()

            // 음독 / 훈독 / 부수 테이블
            readingTable(for: breakdown)

            // 모양 분해
            if !breakdown.components.isEmpty {
                componentsView(for: breakdown.components)
            }

            // FACT 박스
            factBox(text: breakdown.fact)

            // MSG 박스
            msgBox(text: breakdown.msg)
        }
        .padding(20)
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }

    // MARK: Detail — Header

    private func detailHeader(for breakdown: KanjiBreakdown) -> some View {
        HStack(alignment: .top, spacing: 16) {

            // 큰 한자 타일 (soft blue 배경)
            Text(breakdown.kanji)
                .font(.system(size: 48, weight: .heavy))
                .foregroundColor(.themeTextPrimary)
                .frame(width: 84, height: 84)
                .background(
                    RoundedRectangle(cornerRadius: ThemeRadius.medium)
                        .fill(Color.themeBlueSoft)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(breakdown.meaning)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // 부수 pill
                radicalPill(text: breakdown.radical)
            }

            Spacer(minLength: 0)
        }
    }

    /// `부수 力` 형태의 블루 pill.
    /// radical 전체 문자열(`力 (힘 력)`)에서 한자 부분만 추출해 간결하게 표시.
    private func radicalPill(text: String) -> some View {
        // "力 (힘 력)" → "力"
        let radicalChar = text
            .split(separator: " ").first
            .map { String($0) } ?? text

        return HStack(spacing: 4) {
            Text("부수")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.themeBlue.opacity(0.8))
            Text(radicalChar)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeBlue)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color.themeBlueSoft)
        )
    }

    // MARK: Detail — Reading Table

    private func readingTable(for breakdown: KanjiBreakdown) -> some View {
        VStack(spacing: 0) {
            readingRow(label: "음독", value: breakdown.onyomi)

            if !breakdown.kunyomi.isEmpty {
                Divider()
                readingRow(label: "훈독", value: breakdown.kunyomi)
            }

            Divider()
            readingRow(label: "부수", value: breakdown.radical)
        }
    }

    private func readingRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextTertiary)
                .frame(width: 40, alignment: .leading)

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.themeTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
    }

    // MARK: Detail — Components (모양 분해)

    private func componentsView(for components: [KanjiComponent]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("모양 분해")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextSecondary)

            // 각 구성 요소 카드를 세로로 쌓고, 사이에 `+` 커넥터 배치
            VStack(spacing: 6) {
                ForEach(Array(components.enumerated()), id: \.offset) { index, comp in
                    componentCard(comp)

                    // 마지막 요소가 아니면 `+` 커넥터
                    if index < components.count - 1 {
                        plusConnector
                    }
                }
            }
        }
    }

    private func componentCard(_ comp: KanjiComponent) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(comp.char)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.themeTextPrimary)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(comp.meaning)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text(comp.description)
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.medium)
                .fill(Color.themeBlueSoft)
        )
    }

    private var plusConnector: some View {
        Text("+")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.themeTextTertiary)
    }

    // MARK: Detail — FACT / MSG Boxes

    private func factBox(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("FACT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.themeBlue)
                Text("·")
                    .foregroundColor(.themeTextTertiary)
                Text("진짜 어원")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextSecondary)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.themeTextPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.medium)
                .fill(Color.themeBlueSoft)
        )
        .overlay(
            // 좌측 블루 accent 보더
            Rectangle()
                .fill(Color.themeBlue)
                .frame(width: 3)
                .frame(maxHeight: .infinity),
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))
    }

    private func msgBox(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("MSG")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.themeBlue)
                Text("·")
                    .foregroundColor(.white.opacity(0.5))
                Text("뇌피셜 스토리")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.medium)
                .fill(Color.themeDeepNavy)
        )
    }

    // MARK: - Empty State (한자 없는 경우)

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🌱")
                .font(.system(size: 32))
            Text("이 단어는 한자 없이 히라가나/가타카나로만 구성되어 있어요.")
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.themeCardBackground)
        .cornerRadius(ThemeRadius.large)
        .themeCardShadow()
    }
}

// MARK: - Array Safe Index

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

struct KanjiBreakdownSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            KanjiBreakdownSection(breakdowns: [
                KanjiBreakdown(
                    kanji: "勇",
                    meaning: "날랠 용 / 용감할 용",
                    onyomi: "ユウ (YUU)",
                    kunyomi: "いさ-む (isa-mu) — 용기를 내다, 기운을 내다",
                    radical: "力 (힘 력)",
                    components: [
                        KanjiComponent(char: "甬", meaning: "솟아오를 용",
                                       description: "무언가가 솟아오르거나 뚫고 나가는 모양"),
                        KanjiComponent(char: "力", meaning: "힘 력",
                                       description: "글자 그대로 '힘'")
                    ],
                    fact: "'甬(통할 용)'은 '솟아오르다', '뚫고 나아가다'라는 의미를 나타내고, '力(힘 력)'은 글자 그대로 '힘'을 의미합니다. 이 둘이 합쳐져 마음속에서 강한 힘이 솟아나 어떤 어려움도 뚫고 나아갈 수 있는 '용맹함', '용기'를 표현하게 되었어요.",
                    msg: "두려움 속에서도 내면에서 불끈! 솟아오르는(甬) 강한 힘(力)! 그래, 이게 바로 모든 것을 뚫고 나아갈 용기(勇)다. 💪🔥🚀"
                ),
                KanjiBreakdown(
                    kanji: "気",
                    meaning: "기운 기",
                    onyomi: "キ (KI), ケ (KE)",
                    kunyomi: "いき (iki) — 숨",
                    radical: "气 (기운 기)",
                    components: [
                        KanjiComponent(char: "气", meaning: "기운 기",
                                       description: "김이나 수증기가 피어오르는 모양")
                    ],
                    fact: "끓는 물에서 피어오르는 김이나 하늘의 구름을 본떠 만든 상형문자입니다.",
                    msg: "보글보글 끓는 물에서 피어오르는 수증기(气)처럼, 우리의 몸과 마음을 채우는 생명의 기운(気)! 🌬️✨"
                )
            ])
            .padding()
        }
        .background(Color.themeBackground)
    }
}
