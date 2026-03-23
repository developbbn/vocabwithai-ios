//
//  QuizSelectionSheet.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import SwiftUI

// MARK: - 퀴즈 종류
enum QuizType {
    case multipleChoice  // 객관식
    case subjective      // 주관식
    case flashcard       // 플래시카드
}

// MARK: - QuizSelectionSheet
struct QuizSelectionSheet: View {
    @Binding var isPresented: Bool
    var onSelect: (QuizType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 드래그 인디케이터
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 5)
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 20)

            // 타이틀
            Text("어떤 퀴즈를\n풀어볼까요?")
                .font(.system(size: 28, weight: .bold))
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            // 퀴즈 선택 옵션
            VStack(spacing: 12) {
                QuizOptionRow(
                    iconName: "checkmark.circle.fill",
                    iconColor: Color(red: 0.4, green: 0.5, blue: 0.9),
                    iconBg: Color(red: 0.88, green: 0.90, blue: 0.98),
                    title: "객관식 퀴즈",
                    description: "뜻에 맞는 단어를 골라보세요"
                ) {
                    isPresented = false
                    onSelect(.multipleChoice)
                }

                QuizOptionRow(
                    iconName: "pencil.and.list.clipboard",
                    iconColor: Color(red: 0.95, green: 0.55, blue: 0.2),
                    iconBg: Color(red: 0.99, green: 0.92, blue: 0.85),
                    title: "주관식 퀴즈",
                    description: "직접 단어를 입력하며 정확도를\n높여요"
                ) {
                    isPresented = false
                    onSelect(.subjective)
                }

                QuizOptionRow(
                    iconName: "rectangle.on.rectangle.angled",
                    iconColor: Color(red: 0.2, green: 0.75, blue: 0.5),
                    iconBg: Color(red: 0.85, green: 0.96, blue: 0.91),
                    title: "플래시카드",
                    description: "아는 단어인지 빠르게 체크하며\n복습해요"
                ) {
                    isPresented = false
                    onSelect(.flashcard)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }
}

// MARK: - QuizOptionRow
struct QuizOptionRow: View {
    let iconName: String
    let iconColor: Color
    let iconBg: Color
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 아이콘
                Circle()
                    .fill(iconBg)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(iconColor)
                    )

                // 텍스트
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }

                Spacer()

                // 화살표
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(Color(.systemGray6).opacity(0.6))
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview
struct QuizSelectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        QuizSelectionSheet(isPresented: .constant(true)) { _ in }
            .presentationDetents([.medium])
    }
}
