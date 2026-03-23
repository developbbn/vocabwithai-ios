//
//  MultipleChoiceTypeView.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import SwiftUI

// MARK: - 객관식 퀴즈 타입
enum MultipleChoiceType {
    case kanji      // 한자 퀴즈
    case pronunciation // 발음 퀴즈
}

// MARK: - MultipleChoiceTypeView
struct MultipleChoiceTypeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 뒤로가기
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                // 타이틀
                Text("어떤 방식으로\n풀까요?")
                    .font(.system(size: 32, weight: .bold))
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)

                // 퀴즈 타입 카드들
                VStack(spacing: 16) {
                    MultipleChoiceTypeCard(
                        iconName: "textformat",
                        iconColor: .blue,
                        iconBg: Color(red: 0.88, green: 0.92, blue: 0.98),
                        title: "한자 퀴즈",
                        description: "한자를 보고 알맞은 뜻과\n음독/훈독을 선택합니다.",
                        destination: AnyView(MultipleChoiceQuizView(mode: .kanji))
                    )

                    MultipleChoiceTypeCard(
                        iconName: "speaker.wave.2.fill",
                        iconColor: .blue,
                        iconBg: Color(red: 0.88, green: 0.92, blue: 0.98),
                        title: "발음 퀴즈",
                        description: "히라가나 발음을 듣거나\n보고 정확한 소리를 맞힙니다.",
                        destination: AnyView(MultipleChoiceQuizView(mode: .pronunciation))
                    )
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - MultipleChoiceTypeCard
struct MultipleChoiceTypeCard: View {
    let iconName: String
    let iconColor: Color
    let iconBg: Color
    let title: String
    let description: String
    let destination: AnyView

    @State private var navigating = false

    var body: some View {
        Button(action: { navigating = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // 아이콘
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconBg)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 26))
                            .foregroundColor(iconColor)
                    )

                // 텍스트
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)

                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }

                // 시작하기
                HStack(spacing: 4) {
                    Text("시작하기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 2)
        }
        .navigationDestination(isPresented: $navigating) {
            destination
        }
    }
}

// MARK: - Preview
struct MultipleChoiceTypeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MultipleChoiceTypeView()
        }
    }
}
