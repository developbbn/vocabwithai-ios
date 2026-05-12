//
//  SignUpView.swift
//  VocabWithAI
//
//  Created on 2026-04-22
//  Refactored to MVVM on 2026-04-22
//  Added nickname field on 2026-05-12
//
//  이메일/비밀번호로 회원가입하는 화면.
//

import SwiftUI

struct SignUpView: View {

    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                titleSection

                nicknameSection
                emailSection
                passwordSection
                passwordConfirmSection

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }

                signUpButton

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            backButton
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.themeTextPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.themeCardBackground)
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                .contentShape(Rectangle())
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Text("계정 만들기")
            .font(.system(size: 30, weight: .heavy))
            .foregroundColor(.themeTextPrimary)
            .padding(.top, 50)
            .padding(.bottom, 12)
    }

    // MARK: - Nickname Section

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextPrimary)

            HStack(spacing: 10) {
                Image(systemName: "person")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextTertiary)

                TextField("사용할 닉네임을 입력해주세요", text: $viewModel.nickname)
                    .font(.system(size: 15))
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            .padding(14)
            .background(Color.themeCardBackground)
            .cornerRadius(ThemeRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .stroke(Color.themeBorder, lineWidth: 1)
            )

            // 검증 칩 (비밀번호 룰 체크리스트와 동일한 패턴 재활용)
            HStack(spacing: 12) {
                ruleChip(text: "2~20자", isValid: viewModel.isNicknameValid)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Email Section

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이메일")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextPrimary)

            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextTertiary)

                TextField("name@example.com", text: $viewModel.email)
                    .font(.system(size: 15))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            .padding(14)
            .background(Color.themeCardBackground)
            .cornerRadius(ThemeRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .stroke(Color.themeBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Password Section

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("비밀번호")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextPrimary)

            HStack(spacing: 10) {
                Image(systemName: "lock")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextTertiary)

                Group {
                    if viewModel.showPassword {
                        TextField("영문 + 숫자 포함 8자 이상", text: $viewModel.password)
                    } else {
                        SecureField("영문 + 숫자 포함 8자 이상", text: $viewModel.password)
                    }
                }
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

                Button(action: viewModel.togglePasswordVisibility) {
                    Image(systemName: viewModel.showPassword ? "eye" : "eye.slash")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextTertiary)
                }
            }
            .padding(14)
            .background(Color.themeCardBackground)
            .cornerRadius(ThemeRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .stroke(Color.themeBorder, lineWidth: 1)
            )

            // 비밀번호 규칙 체크리스트
            passwordRuleChecklist
        }
    }

    private var passwordRuleChecklist: some View {
        HStack(spacing: 12) {
            ruleChip(text: "8자 이상", isValid: viewModel.hasMinLength)
            ruleChip(text: "영문 포함", isValid: viewModel.hasLetter)
            ruleChip(text: "숫자 포함", isValid: viewModel.hasDigit)
        }
        .padding(.top, 4)
    }

    private func ruleChip(text: String, isValid: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isValid ? .themeBlue : .themeTextTertiary)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(isValid ? .themeBlue : .themeTextTertiary)
        }
    }

    // MARK: - Password Confirm Section

    private var passwordConfirmSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("비밀번호 확인")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextPrimary)

            HStack(spacing: 10) {
                Image(systemName: viewModel.isPasswordMatched ? "checkmark" : "lock")
                    .font(.system(size: 14, weight: viewModel.isPasswordMatched ? .bold : .regular))
                    .foregroundColor(viewModel.isPasswordMatched ? .themeBlue : .themeTextTertiary)

                Group {
                    if viewModel.showPasswordConfirm {
                        TextField("비밀번호를 한 번 더 입력", text: $viewModel.passwordConfirm)
                    } else {
                        SecureField("비밀번호를 한 번 더 입력", text: $viewModel.passwordConfirm)
                    }
                }
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

                Button(action: viewModel.togglePasswordConfirmVisibility) {
                    Image(systemName: viewModel.showPasswordConfirm ? "eye" : "eye.slash")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextTertiary)
                }
            }
            .padding(14)
            .background(Color.themeCardBackground)
            .cornerRadius(ThemeRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .stroke(passwordConfirmBorderColor, lineWidth: viewModel.isPasswordMatched ? 1.5 : 1)
            )
        }
    }

    private var passwordConfirmBorderColor: Color {
        if viewModel.isPasswordMatched {
            return .themeBlue
        } else if !viewModel.passwordConfirm.isEmpty && viewModel.password != viewModel.passwordConfirm {
            return Color.red.opacity(0.6)
        } else {
            return .themeBorder
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(.red)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.red.opacity(0.08))
        .cornerRadius(ThemeRadius.small)
    }

    // MARK: - Sign Up Button

    private var signUpButton: some View {
        Button(action: viewModel.signUp) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.themeTextSecondary)
                } else {
                    Text("회원가입")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(viewModel.isFormValid ? .themeTextPrimary : .themeTextTertiary)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .fill(Color.themeBlueSoft)
            )
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.top, 4)
    }
}

#Preview {
    SignUpView()
}
