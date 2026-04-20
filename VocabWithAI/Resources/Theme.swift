//
//  Theme.swift
//  VocabApp
//
//  Created on 2026-04-20
//
//  PDF 디자인 (화이트 + 블루 테마) 전역 토큰.
//  WordDetailView 개편 기준으로 정리됨.
//

import SwiftUI

// MARK: - Color Palette

extension Color {

    // MARK: Brand Blue

    /// 메인 액센트 블루. 히라가나 텍스트, 블루 pill, 링크성 강조에 사용.
    /// PDF 기준 대략 #2563EB 계열.
    static let themeBlue = Color(red: 0.15, green: 0.39, blue: 0.92)

    /// 연한 블루 배경. WORD 배지, 부수 pill, FACT 박스, 한자 타일 등 soft tint.
    /// PDF 기준 #EFF4FF 계열.
    static let themeBlueSoft = Color(red: 0.94, green: 0.96, blue: 1.0)

    /// 연한 블루보다 살짝 진한 블루 배경. 선택되지 않은 Kanji 탭, 구분감 필요한 soft tint.
    static let themeBlueSoft2 = Color(red: 0.90, green: 0.93, blue: 0.99)

    // MARK: Deep Navy

    /// 다크 네이비. 선택된 Kanji 탭 배경, MSG(뇌피셜) 박스 배경.
    /// PDF 기준 #1A2540 계열.
    static let themeDeepNavy = Color(red: 0.10, green: 0.14, blue: 0.25)

    // MARK: Surface

    /// 페이지 배경. 거의 흰색에 살짝 블루끼.
    static let themeBackground = Color(red: 0.97, green: 0.98, blue: 1.0)

    /// 카드 배경 (순백).
    static let themeCardBackground = Color.white

    // MARK: Text

    /// 기본 텍스트 (거의 검정, 살짝 누그러뜨림).
    static let themeTextPrimary = Color(red: 0.07, green: 0.09, blue: 0.15)

    /// 보조 텍스트 (설명, 캡션).
    static let themeTextSecondary = Color(red: 0.45, green: 0.48, blue: 0.55)

    /// 매우 옅은 텍스트 (서브타이틀, 힌트).
    static let themeTextTertiary = Color(red: 0.60, green: 0.63, blue: 0.70)

    // MARK: Divider / Border

    static let themeBorder = Color(red: 0.90, green: 0.92, blue: 0.96)
}

// MARK: - Radius

enum ThemeRadius {
    /// 작은 pill, badge 등.
    static let small: CGFloat = 8
    /// 일반 카드 내부 요소 (구성요소 카드, 단어 행 등).
    static let medium: CGFloat = 12
    /// 큰 카드 (WordHero, 섹션 컨테이너 카드).
    static let large: CGFloat = 20
    /// 원형에 가까운 pill / 탭 selector.
    static let pill: CGFloat = 16
}

// MARK: - Shadow

extension View {
    /// 카드 공통 soft shadow. `.themeCardShadow()` 로 사용.
    func themeCardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.04),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Section Badge Color

/// 섹션 01/02/03 원형 배지 색상.
/// PDF 기준 짙은 네이비 채움 + 흰색 숫자.
enum SectionBadgeStyle {
    static let background = Color.themeDeepNavy
    static let foreground = Color.white
}
