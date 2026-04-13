//
//  MultipleChoiceQuizView.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import SwiftUI

struct MultipleChoiceQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MultipleChoiceQuizViewModel
    @State private var showExitConfirm = false

    init(mode: MultipleChoiceMode) {
        _viewModel = StateObject(wrappedValue: MultipleChoiceQuizViewModel(mode: mode))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            if viewModel.questions.isEmpty {
                emptyState
            } else if viewModel.isFinished {
                resultView
            } else {
                VStack(spacing: 0) {
                    // 네비게이션 바
                    navBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)

                    // 진행 상태
                    progressSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // 문제 카드
                    questionCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)

                    // 선지
                    choiceList
                        .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.bottom, 100) // 다음으로 버튼 공간

                // 다음으로 버튼 (하단 고정)
                nextButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .overlay {
            if showExitConfirm {
                // 배경 딤
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showExitConfirm = false }

                // 슬라이드 시트
                VStack {
                    Spacer()
                    exitConfirmSheet
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showExitConfirm)
            }
        }
    }

    // MARK: - 종료 확인 시트
    private var exitConfirmSheet: some View {
        VStack(spacing: 0) {
            // 핸들
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // 타이틀
            Text("퀴즈를 종료할까요?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 8)

            Text("현재까지 푼 문제로 결과가 집계돼요")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.bottom, 28)

            // 버튼
            VStack(spacing: 12) {
                Button(action: {
                    showExitConfirm = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.finishEarly()
                    }
                }) {
                    Text("지금까지 결과 보기")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(14)
                }

                Button(action: { showExitConfirm = false }) {
                    Text("계속 풀기")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

    // MARK: - 네비게이션 바
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            Spacer()
            Text("단어 퀴즈")
                .font(.system(size: 18, weight: .semibold))
            Spacer()
            Button(action: { showExitConfirm = true }) {
                Text("퀴즈 종료")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
    }

    // MARK: - 진행 상태
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("오늘의 학습")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                HStack(spacing: 2) {
                    Text("\(viewModel.currentIndex + 1)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    Text("/ \(viewModel.totalCount)")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }

            // 진행 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(
                            width: geometry.size.width * CGFloat(viewModel.currentIndex + 1) / CGFloat(viewModel.totalCount),
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - 문제 카드
    private var questionCard: some View {
        VStack(spacing: 12) {
            Text(viewModel.currentQuestion?.prompt ?? "")
                .font(.system(size: 64, weight: .bold))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.vertical, 32)

            Text(viewModel.questionText)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 2)
    }

    // MARK: - 선지 목록
    private var choiceList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.currentQuestion?.choices ?? [], id: \.self) { choice in
                ChoiceRow(
                    text: choice,
                    state: choiceState(for: choice),
                    action: { viewModel.select(choice) }
                )
            }
        }
    }

    // MARK: - 다음으로 버튼
    private var nextButton: some View {
        Button(action: { viewModel.next() }) {
            Text(viewModel.currentIndex + 1 == viewModel.totalCount ? "결과 보기" : "다음으로")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(viewModel.isAnswered ? Color.blue : Color.blue.opacity(0.3))
                .cornerRadius(16)
        }
        .disabled(!viewModel.isAnswered)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isAnswered)
    }

    // MARK: - 빈 상태
    private var emptyState: some View {
        VStack(spacing: 0) {
            navBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.4))
                Text("퀴즈를 풀 수 있는 단어가 없어요")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gray)
                Text("단어를 등록하면 AI가 퀴즈를\n자동으로 준비해드려요!")
                    .font(.system(size: 15))
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - 결과 화면
    private var resultView: some View {
        VStack(spacing: 0) {
            Spacer()

            // 원형 진행 그래프
            ZStack {
                // 배경 링
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: 16)
                    .frame(width: 200, height: 200)

                // 점수 링
                Circle()
                    .trim(from: 0, to: viewModel.accuracy)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: viewModel.accuracy)

                // 중앙 텍스트
                VStack(spacing: 4) {
                    Text("최종 점수")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(viewModel.scoreText)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(Int(viewModel.accuracy * 100))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 40)

            // 결과 멘트
            VStack(spacing: 10) {
                Text(viewModel.resultTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                Text(viewModel.resultSubtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // 버튼
            VStack(spacing: 16) {
                if !viewModel.wrongQuestions.isEmpty {
                    Button(action: { /* TODO: 틀린 문제 복습 */ }) {
                        HStack(spacing: 8) {
                            Text("틀린 문제 \(viewModel.wrongQuestions.count)개 확인하기")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                } else {
                    Button(action: { viewModel.restart() }) {
                        Text("다시 풀기")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                }

                Button(action: { dismiss() }) {
                    Text("홈으로 이동")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Helper
    private func choiceState(for choice: String) -> ChoiceRow.ChoiceState {
        guard viewModel.isAnswered else { return .normal }
        let isAnswer = choice == viewModel.currentQuestion?.answer
        let isSelected = choice == viewModel.selectedChoice

        if isAnswer { return .correct }
        if isSelected { return .wrong }
        return .normal
    }
}

// MARK: - ChoiceRow
struct ChoiceRow: View {
    enum ChoiceState { case normal, correct, wrong }

    let text: String
    let state: ChoiceState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.system(size: 17, weight: state == .normal ? .regular : .semibold))
                    .foregroundColor(textColor)
                Spacer()
                Circle()
                    .strokeBorder(borderColor, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle().fill(fillColor)
                    )
                    .overlay(
                        Circle()
                            .fill(dotColor)
                            .frame(width: 10, height: 10)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(backgroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: state == .normal ? 1 : 2)
            )
        }
        .disabled(state != .normal)
    }

    private var textColor: Color {
        switch state {
        case .normal:  return .black
        case .correct: return .blue
        case .wrong:   return .red
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .normal:  return .white
        case .correct: return Color(red: 0.93, green: 0.96, blue: 1.0)
        case .wrong:   return Color(red: 1.0, green: 0.94, blue: 0.94)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:  return Color.gray.opacity(0.25)
        case .correct: return .blue
        case .wrong:   return .red
        }
    }

    private var fillColor: Color {
        switch state {
        case .normal:  return .clear
        case .correct: return .blue
        case .wrong:   return .red
        }
    }

    private var dotColor: Color {
        state == .normal ? .clear : .white
    }
}

// MARK: - Preview
struct MultipleChoiceQuizView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MultipleChoiceQuizView(mode: .kanji)
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
