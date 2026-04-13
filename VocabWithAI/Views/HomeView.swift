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
                        HeaderView(userName: viewModel.userName)
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

// MARK: - Header View
struct HeaderView: View {
    let userName: String
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )

                Text("\(userName)님, 오늘도 즐겁게 시작해볼까요? ✨")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                // Delete Button (테스트용)
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.6))
                }
                .padding(.trailing, 8)

                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.black)
                }
            }

            Spacer()
        }
        .confirmationDialog(
            "모든 단어를 삭제하시겠어요?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("전체 삭제", role: .destructive) {
                deleteAllWords()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("저장된 모든 단어가 삭제됩니다. (테스트용)")
        }
    }

    private func deleteAllWords() {
        WordRepository.shared.deleteAllWords()
        DailyStatsManager.shared.resetData()
        DailyPhraseViewModel.shared.resetData()
        print("🗑️ 모든 단어 삭제 완료")
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
                subLabel: "완료",
                valueColor: .blue,
                isDone: false
            )
            StatCard(
                label: "푼 퀴즈",
                value: "\(stats.quizCount)개",
                subLabel: "통과",
                valueColor: Color(red: 0.55, green: 0.2, blue: 0.9),
                isDone: false
            )
            StatCard(
                label: "표현 학습",
                value: stats.expressionDone ? "✅" : "❌",
                subLabel: stats.expressionDone ? "완료" : "미완료",
                valueColor: .green,
                isDone: false
            )
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String?
    let subLabel: String
    let valueColor: Color
    let isDone: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(valueColor)

            Text(value ?? "")
                .font(.system(size: 24, weight: .bold))
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
                iconColor: .blue,
                action: onLogTap
            )
            FeatureCard(
                title: "오늘의 표현",
                icon: "message.fill",
                iconColor: .blue,
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
            VStack(alignment: .leading) {
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
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                VStack {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.leading, 20)
                            .padding(.top, 20)
                        Spacer()
                    }
                    Spacer()
                }
            )
        }
    }
}

// MARK: - Recently Learned View
struct RecentlyLearnedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 학습한 단어")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 140, height: 80)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
