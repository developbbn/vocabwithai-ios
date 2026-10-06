//
//  AddWordView.swift
//  VocabApp
//
//  Created on 2026-02-03
//  2026-10-06 UI 개편: 미리보기 카드 + 단어/뜻 2단 배치 + '선택' 뱃지 + 포커스 하이라이트.
//

import SwiftUI

struct AddWordView: View {
    @StateObject private var viewModel = AddWordViewModel()
    @Environment(\.dismiss) private var dismiss

    // 포커스 대상 필드
    private enum Field { case word, meaning, pronunciation, memo }
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Nav Bar
                navBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        titleSection.padding(.top, 20)
                        previewCard
                        wordMeaningRow
                        pronunciationField
                        memoField
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }

            // 고정 등록 버튼
            registerButton
                .padding(.horizontal, 20)
                .padding(.bottom, 34)

            // 토스트 팝업 (동적 메시지)
            ToastView(message: viewModel.toastMessage, isShowing: $viewModel.showToast)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            Spacer()
            infoIcon(color: .blue, size: 28, fontSize: 16)
        }
    }

    // MARK: - Title
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("단어 등록")
                .font(.system(size: 30, weight: .bold))
            Text("기억하고 싶은 단어를 추가해 보세요.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
    }

    // MARK: - 미리보기 카드
    private var previewCard: some View {
        ZStack(alignment: .leading) {
            // 그라데이션 배경
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.56, blue: 0.98),
                    Color(red: 0.15, green: 0.39, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 語 워터마크 (우측, 반투명)
            HStack {
                Spacer()
                Text("語")
                    .font(.system(size: 150, weight: .heavy))
                    .foregroundColor(.white.opacity(0.12))
                    .offset(x: 30)
            }

            // 내용
            VStack(alignment: .leading, spacing: 8) {
                Text("미리보기")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text(viewModel.word.isEmpty ? "Apple" : viewModel.word)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(viewModel.word.isEmpty ? .white.opacity(0.6) : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(20)
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 단어 / 뜻 (2단 배치)
    private var wordMeaningRow: some View {
        HStack(alignment: .top, spacing: 14) {
            wordField
            meaningField
        }
    }

    // MARK: - 단어 필드
    private var wordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("단어")

            TextField("예: Apple", text: $viewModel.word)
                .font(.system(size: 16))
                .accentColor(.blue)
                .focused($focusedField, equals: .word)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(fieldBackground(.word))

            if let error = viewModel.wordError {
                errorText(error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 뜻 필드
    private var meaningField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("뜻")

            TextField("예: 사과", text: $viewModel.meaning)
                .font(.system(size: 16))
                .accentColor(.blue)
                .focused($focusedField, equals: .meaning)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(fieldBackground(.meaning))

            if let error = viewModel.meaningError {
                errorText(error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 발음 필드
    private var pronunciationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabelOptional("발음")

            TextField("예: [æpl]", text: $viewModel.pronunciation)
                .font(.system(size: 16))
                .accentColor(.blue)
                .focused($focusedField, equals: .pronunciation)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(fieldBackground(.pronunciation))
        }
    }

    // MARK: - 메모 필드
    private var memoField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabelOptional("메모 또는 예문")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.memo)
                    .font(.system(size: 16))
                    .accentColor(.blue)
                    .focused($focusedField, equals: .memo)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(.top, 1)

                if viewModel.memo.isEmpty {
                    Text("예문을 적으면 더 잘 외워져요.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 3)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 120)
            .background(fieldBackground(.memo))
        }
    }

    // MARK: - 등록 버튼
    private var registerButton: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            viewModel.registerWord()
        }) {
            Text("등록하기")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.isRegisterEnabled ? Color.blue : Color.blue.opacity(0.4))
                .cornerRadius(14)
        }
        .disabled(!viewModel.isRegisterEnabled)
    }

    // MARK: - Reusable Components

    /// 필드 배경: 포커스 시 흰 배경 + 파란 테두리, 평소엔 회색.
    private func fieldBackground(_ field: Field) -> some View {
        let isFocused = focusedField == field
        return RoundedRectangle(cornerRadius: 14)
            .fill(isFocused ? Color.white : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1.5)
            )
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
    }

    /// '선택' 뱃지 + info 아이콘이 붙는 라벨 (발음 / 메모용).
    private func fieldLabelOptional(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            optionalBadge
            infoIcon(color: .gray.opacity(0.5), size: 18, fontSize: 11)
        }
    }

    private var optionalBadge: some View {
        Text("선택")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(.systemGray5))
            .cornerRadius(6)
    }

    private func infoIcon(color: Color, size: CGFloat, fontSize: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Text("i")
                    .font(.system(size: fontSize, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            )
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundColor(.red)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            Spacer()

            if isShowing {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )

                    Text(message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.78))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

// MARK: - Preview
struct AddWordView_Previews: PreviewProvider {
    static var previews: some View {
        AddWordView()
    }
}
