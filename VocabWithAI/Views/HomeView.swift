//
//  HomeView.swift
//  VocabApp
//
//  Created on 2026-01-27
//  2026-10-06 홈 개편: 단어퀴즈 히어로 카드 + 단어등록 플로팅 버튼 구조로 변경.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddWord: Bool = false
    @State private var showQuizSheet: Bool = false
    @State private var showFlashcard: Bool = false
    @State private var showMultipleChoiceType: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header
                            HeaderView()
                                .padding(.horizontal, 20)
                                .padding(.top, 20)

                            // 단어퀴즈 히어로 카드 (스탯 내장) — 화면 높이에 맞춰 유동 높이
                            QuizHeroCard(
                                cardHeight: heroCardHeight(for: geo.size.height),
                                onStart: { showQuizSheet = true }
                            )
                            .padding(.horizontal, 20)

                            // 단어등록 플로팅 버튼 (우측, 카드 아래)
                            HStack {
                                Spacer()
                                AddWordFloatingButton(action: { showAddWord = true })
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)

                            Spacer(minLength: 20)
                        }
                        // 화면보다 짧으면 위로 정렬, 길면(Dynamic Type 등) 스크롤 허용
                        .frame(minHeight: geo.size.height, alignment: .top)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showAddWord) {
                AddWordView()
            }
            .navigationDestination(isPresented: $showMultipleChoiceType) {
                MultipleChoiceTypeView()
            }
            .navigationDestination(isPresented: $showFlashcard) {
                FlashcardView()
            }
            .sheet(isPresented: $showQuizSheet) {
                QuizSelectionSheet(isPresented: $showQuizSheet) { quizType in
                    switch quizType {
                    case .multipleChoice:
                        showMultipleChoiceType = true
                    case .flashcard:
                        showFlashcard = true
                    default:
                        break
                    }
                }
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    /// 히어로 카드 높이 = 사용 가능 높이에서 헤더·버튼·여백(약 220pt)을 뺀 값.
    /// SE 같은 작은 화면에서도 단어등록 버튼까지 한 화면에 들어오도록 상한 440 / 하한 300으로 클램프.
    private func heroCardHeight(for availableHeight: CGFloat) -> CGFloat {
        let reserved: CGFloat = 230
        return min(max(availableHeight - reserved, 300), 440)
    }
}

// MARK: - Header Confirmation

/// HomeView 헤더에서 띄울 수 있는 확인 종류.
/// enum 기반 단일 sheet 로 처리해서 multiple .sheet/.confirmationDialog 충돌 버그 회피.
private enum HeaderConfirmation: Identifiable {
    case logout
    case deleteAllWords  // 테스트용 (DEBUG 빌드에서만 트리거됨)

    var id: Self { self }

    var title: String {
        switch self {
        case .logout:         return "정말 로그아웃 하시겠어요?"
        case .deleteAllWords: return "모든 단어를 삭제할까요?"
        }
    }

    var message: String {
        switch self {
        case .logout:         return "다시 로그인이 필요해요."
        case .deleteAllWords: return "저장된 모든 단어가 삭제됩니다. (테스트용)"
        }
    }

    var confirmLabel: String {
        switch self {
        case .logout:         return "로그아웃"
        case .deleteAllWords: return "전체 삭제"
        }
    }

    var confirmColor: Color {
        switch self {
        case .logout:         return .black
        case .deleteAllWords: return .red
        }
    }

    var sheetHeight: CGFloat { 240 }
}

// MARK: - Header View
struct HeaderView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var activeConfirmation: HeaderConfirmation?
    @State private var logoutErrorMessage: String?

    private var displayName: String {
        if let name = authManager.currentUser?.displayName, !name.isEmpty {
            return name
        }
        if let email = authManager.currentUser?.email {
            return String(email.prefix(while: { $0 != "@" }))
        }
        return "사용자"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 프로필 Circle — 탭하면 로그아웃 확인 시트
            Button(action: { activeConfirmation = .logout }) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .buttonStyle(.plain)

            Text("\(displayName)님,\n오늘도 즐겁게 시작해볼까요?\n✨")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            Spacer()

            HStack(spacing: 12) {
                #if DEBUG
                // 테스트용 — DEBUG 빌드에서만 보임 (App Store Release 빌드엔 자동 제거)
                Button(action: { activeConfirmation = .deleteAllWords }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.6))
                }
                #endif

                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.black)
                }
            }
            .padding(.top, 8)
        }
        // 단일 sheet (logout / deleteAllWords 둘 다 처리) - 커스텀 바텀 시트
        .sheet(item: $activeConfirmation) { confirmation in
            ConfirmationBottomSheet(
                title: confirmation.title,
                message: confirmation.message,
                confirmLabel: confirmation.confirmLabel,
                confirmColor: confirmation.confirmColor,
                onConfirm: {
                    handleConfirmationAction(for: confirmation)
                }
            )
            .presentationDetents([.height(confirmation.sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        // 에러 알림 — .constant 대신 정상 binding 사용
        .alert(
            "로그아웃 실패",
            isPresented: Binding(
                get: { logoutErrorMessage != nil },
                set: { if !$0 { logoutErrorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(logoutErrorMessage ?? "")
        }
    }

    // MARK: - Actions

    /// 바텀 시트의 "확인" 액션 처리.
    /// 시트를 먼저 닫고 후속 액션 실행 (시트 닫히는 애니메이션과 충돌 방지).
    private func handleConfirmationAction(for confirmation: HeaderConfirmation) {
        activeConfirmation = nil

        switch confirmation {
        case .logout:
            // RootView 가 전체 화면 교체해줘서 애니메이션 충돌 없음
            handleLogout()
        case .deleteAllWords:
            // 화면 전환 없이 데이터만 삭제 → 시트 닫히는 거랑 충돌 없음
            deleteAllWords()
        }
    }

    private func deleteAllWords() {
        WordRepository.shared.deleteAllWords()
        DailyStatsManager.shared.resetData()
        DailyPhraseViewModel.shared.resetData()
        print("🗑️ 모든 단어 삭제 완료")
    }

    private func handleLogout() {
        do {
            try authManager.signOut()
            print("👋 로그아웃 완료")
            // 성공 시 RootView가 자동으로 LoginView로 전환
        } catch {
            logoutErrorMessage = "로그아웃 중 오류가 발생했습니다. 다시 시도해주세요."
            print("❌ 로그아웃 실패: \(error)")
        }
    }
}

// MARK: - Quiz Hero Card
/// 신규 홈의 메인. 단어퀴즈 진입 + 오늘의 단어/푼 퀴즈 스탯을 한 카드에 통합.
struct QuizHeroCard: View {
    @ObservedObject private var stats = DailyStatsManager.shared
    let cardHeight: CGFloat
    let onStart: () -> Void

    private let darkCard = Color(red: 0.09, green: 0.10, blue: 0.13)

    var body: some View {
        ZStack {
            // 뒤에 쌓인 카드 효과 (deck 느낌)
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.themeBlue.opacity(0.30))
                .offset(x: 12, y: -14)

            RoundedRectangle(cornerRadius: 28)
                .fill(Color.themeBlue.opacity(0.55))
                .offset(x: -12, y: 14)

            // 메인 다크 카드
            VStack(alignment: .leading, spacing: 0) {
                // 상단: 라벨 + 스탯
                HStack(alignment: .top) {
                    Text("WORD QUIZ")
                        .font(.system(size: 15, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)

                    Spacer()

                    HStack(alignment: .top, spacing: 22) {
                        heroStat(value: stats.wordCount, label: "오늘의 단어")
                        heroStat(value: stats.quizCount, label: "푼 퀴즈")
                    }
                }

                Spacer()

                // 중앙: 한자 + 설명
                Text("語")
                    .font(.system(size: 96, weight: .heavy))
                    .foregroundColor(.white)

                Text("외운 단어를 퀴즈로 확인해요")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 10)

                Spacer()

                // 하단: 시작 버튼
                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Text("단어퀴즈 시작하기")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.themeBlue)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(darkCard)
            .cornerRadius(28)
        }
        .frame(height: cardHeight)
    }

    /// 카드 상단 우측 스탯 1개 (숫자 위, 라벨 아래).
    private func heroStat(value: Int, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Add Word Floating Button
/// 단어등록 진입. 흰색 pill + 다크 플러스 아이콘.
struct AddWordFloatingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.09, green: 0.10, blue: 0.13))
                        .frame(width: 30, height: 30)
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("단어등록")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.leading, 12)
            .padding(.trailing, 22)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthManager.shared)
    }
}
