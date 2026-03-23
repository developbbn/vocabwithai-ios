//
//  FlashcardView.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import SwiftUI

// MARK: - FlashcardView
struct FlashcardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FlashcardViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // 네비게이션 바
                navBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                if viewModel.words.isEmpty {
                    emptyState
                } else if viewModel.isFinished {
                    resultView
                } else {
                    // 카드 + 버튼
                    VStack(spacing: 40) {
                        // 진행 상태
                        progressBar

                        // 플래시카드
                        flashCard
                            .padding(.horizontal, 20)

                        Spacer()

                        // 몰라요 / 알아요 버튼
                        answerButtons
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - 네비게이션 바
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }

            Spacer()

            Text("단어 퀴즈")
                .font(.system(size: 18, weight: .semibold))

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - 진행 바
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.words.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < viewModel.currentIndex
                          ? Color.blue
                          : index == viewModel.currentIndex
                            ? Color.blue.opacity(0.4)
                            : Color.gray.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut, value: viewModel.currentIndex)
    }

    // MARK: - 플래시카드
    private var flashCard: some View {
        ZStack {
            // 카드 뒷면 (뜻)
            cardBack
                .opacity(viewModel.isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(viewModel.isFlipped ? 0 : -90), axis: (x: 0, y: 1, z: 0))

            // 카드 앞면 (단어)
            cardFront
                .opacity(viewModel.isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(viewModel.isFlipped ? 90 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.isFlipped.toggle()
            }
        }
    }

    private var cardFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)

            VStack(spacing: 20) {

                Spacer()

                // 단어
                Text(viewModel.currentWord?.word ?? "")
                    .font(.system(size: 72, weight: .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal, 20)

                // 발음
//                if let pronunciation = viewModel.currentWord?.pronunciation, !pronunciation.isEmpty {
//                    Text(pronunciation)
//                        .font(.system(size: 20))
//                        .foregroundColor(.gray)
//                }

                Spacer()

                // 탭 힌트
                Text("탭하여 뜻 확인하기")
                    .font(.system(size: 15))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, 24)
            }
        }
    }

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)

            VStack(spacing: 16) {
                Spacer()

                // 단어 (작게)
                Text(viewModel.currentWord?.word ?? "")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.gray.opacity(0.4))
                
                // 발음
                Text(viewModel.currentWord?.pronunciation ?? "")
                    .font(.system(size: 23))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray.opacity(0.4))
                    .padding(.horizontal, 24)


                // 뜻
                Text(viewModel.currentWord?.meaning ?? "")
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                

                // 메모
                if let memo = viewModel.currentWord?.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }

                Spacer()

                Text("탭하여 단어 보기")
                    .font(.system(size: 15))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 답변 버튼
    private var answerButtons: some View {
        HStack(spacing: 60) {
            // 몰라요
            VStack(spacing: 10) {
                Button(action: {
                    viewModel.answer(knew: false)
                }) {
                    Circle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.red)
                        )
                }

                Text("몰라요")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.red)
            }

            // 알아요
            VStack(spacing: 10) {
                Button(action: {
                    viewModel.answer(knew: true)
                }) {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "circle")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.green)
                        )
                }

                Text("알아요")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - 빈 상태
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            Text("저장된 단어가 없어요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)
            Text("단어를 먼저 등록해보세요!")
                .font(.system(size: 15))
                .foregroundColor(.gray.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - 결과 화면
    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)

            Text("완료!")
                .font(.system(size: 32, weight: .bold))

            VStack(spacing: 8) {
                Text("알아요 \(viewModel.knewCount)개 · 몰라요 \(viewModel.didntKnowCount)개")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(spacing: 12) {
                // 모르는 단어 다시 풀기
                if viewModel.didntKnowCount > 0 {
                    Button(action: { viewModel.retryUnknown() }) {
                        Text("모르는 단어만 다시 풀기")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(14)
                    }
                }

                Button(action: { viewModel.restart() }) {
                    Text("처음부터 다시 풀기")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(14)
                }

                Button(action: { dismiss() }) {
                    Text("종료")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview
struct FlashcardView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardView()
    }
}
