//
//  HomeView.swift
//  VocabApp
//
//  Created on 2026-01-27
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddWord: Bool = false
    @State private var showDailyPhrase: Bool = false
    @State private var showQuizSheet: Bool = false
    @State private var showFlashcard: Bool = false
    @State private var showMultipleChoiceType: Bool = false
    @State private var showSongList: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HeaderView()
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        // Stat Cards (3개)
                        StatCardsView()
                            .padding(.horizontal, 20)

                        // Feature Grid
                        FeatureGridView(
                            onQuizTap: { showQuizSheet = true },
                            onLogTap: { showAddWord = true },
                            onExpressionTap: { showDailyPhrase = true },
                            onListeningTap: { showSongList = true }
                        )
                        .padding(.horizontal, 20)

                        // Recently Learned Section
                        RecentlyLearnedView()
                            .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showSongList) {
                SongListView()
            }
            .navigationDestination(isPresented: $showAddWord) {
                AddWordView()
            }
            .navigationDestination(isPresented: $showDailyPhrase) {
                PhraseDetailView()
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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if DailyPhraseViewModel.shared.currentPhrase == nil {
                        DailyPhraseViewModel.shared.generateTodayPhrase()
                        print("🔮 오늘의 표현 백그라운드 로드 시작")
                    }
                }
            }
        }
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

// MARK: - Stat Cards View (3개 카드)
struct StatCardsView: View {
    @ObservedObject private var stats = DailyStatsManager.shared

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                label: "오늘의 단어",
                value: "\(stats.wordCount)개",
                subLabel: "완료"
            )
            StatCard(
                label: "푼 퀴즈",
                value: "\(stats.quizCount)개",
                subLabel: "통과"
            )
            StatCard(
                label: "표현 학습",
                value: stats.expressionDone ? "✅" : "❌",
                subLabel: stats.expressionDone ? "완료" : "미완료"
            )
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String?
    let subLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Text(value ?? "")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)

            Text(subLabel)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .padding(.horizontal, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Feature Grid View
struct FeatureGridView: View {
    let onQuizTap: () -> Void
    let onLogTap: () -> Void
    let onExpressionTap: () -> Void
    let onListeningTap: () -> Void

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            FeatureCard(
                title: "단어퀴즈",
                icon: "gamecontroller.fill",
                iconColor: .blue,
                action: onQuizTap
            )
            FeatureCard(
                title: "단어등록",
                icon: "plus.circle.fill",
                iconColor: .green,
                action: onLogTap
            )
            FeatureCard(
                title: "오늘의 표현",
                icon: "message.fill",
                iconColor: .orange,
                action: onExpressionTap
            )
            FeatureCard(
                title: "노래감상",
                icon: "music.note",
                iconColor: .pink,
                action: onListeningTap
            )
        }
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))

                // Title at top-left
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                    .padding(.top, 20)

                // Icon at bottom-right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(iconColor)
                            )
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recently Learned View
struct RecentlyLearnedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 학습한 단어")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)

            HStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthManager.shared)
    }
}
