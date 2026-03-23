//
//  AddWordView.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import SwiftUI

struct AddWordView: View {
    @StateObject private var viewModel = AddWordViewModel()
    @Environment(\.dismiss) private var dismiss
    
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
                    VStack(alignment: .leading, spacing: 28) {
                        titleSection.padding(.top, 28)
                        wordField
                        meaningField
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
    
    // MARK: - 단어 필드
    private var wordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("단어")
            
            HStack {
                TextField("예: Apple", text: $viewModel.word)
                    .font(.system(size: 16))
                    .accentColor(.blue)
                
                if !viewModel.word.isEmpty {
                    clearButton { viewModel.word = "" }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.systemGray6))
            .cornerRadius(14)
            
            if let error = viewModel.wordError {
                errorText(error)
            }
        }
    }
    
    // MARK: - 뜻 필드
    private var meaningField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("뜻")
            
            TextField("예: 사과", text: $viewModel.meaning)
                .font(.system(size: 16))
                .accentColor(.blue)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(.systemGray6))
                .cornerRadius(14)
            
            if let error = viewModel.meaningError {
                errorText(error)
            }
        }
    }
    
    // MARK: - 발음 필드
    private var pronunciationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabelWithInfo("발음 (선택)")
            
            TextField("예: [æpl]", text: $viewModel.pronunciation)
                .font(.system(size: 16))
                .accentColor(.blue)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(.systemGray6))
                .cornerRadius(14)
        }
    }
    
    // MARK: - 메모 필드
    private var memoField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabelWithInfo("메모 또는 예문 (선택)")
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.memo)
                    .font(.system(size: 16))
                    .accentColor(.blue)
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
            .background(Color(.systemGray6))
            .cornerRadius(14)
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
    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
    }
    
    private func fieldLabelWithInfo(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            infoIcon(color: .gray.opacity(0.5), size: 18, fontSize: 11)
        }
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
    
    private func clearButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
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
