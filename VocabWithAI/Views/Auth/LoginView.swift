//
//  LoginView.swift
//  VocabWithAI
//
//  Created on 2026-04-22
//  Refactored to MVVM on 2026-04-22
//
//  이메일/비밀번호로 로그인하는 화면.
//

import SwiftUI

struct LoginView: View {

    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Spacer().frame(height: 40)

                titleSection

                emailSection
                passwordSection

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }

                forgotPasswordLink

                loginButton

                orDivider

                signUpButton

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .sheet(isPresented: $viewModel.showSignUp) {
            SignUpView()
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("단어장")
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(.themeTextPrimary)

            Text("KOTOBA")
                .font(.system(size: 14, weight: .bold))
                .tracking(2)
                .foregroundColor(.themeBlue)
        }
        .padding(.bottom, 16)
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
                    .stroke(fieldBorderColor, lineWidth: 1)
            )
        }
    }

    private var fieldBorderColor: Color {
        viewModel.errorMessage != nil ? Color.red.opacity(0.6) : Color.themeBorder
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
                        TextField("6자 이상 입력해주세요", text: $viewModel.password)
                    } else {
                        SecureField("6자 이상 입력해주세요", text: $viewModel.password)
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
                    .stroke(fieldBorderColor, lineWidth: 1)
            )
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

    // MARK: - Forgot Password Link

    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button("비밀번호를 잊으셨나요?") {
                viewModel.openPasswordReset()
            }
            .font(.system(size: 13))
            .foregroundColor(.themeTextSecondary)
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button(action: viewModel.signIn) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.themeTextSecondary)
                } else {
                    Text("로그인")
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
    }

    // MARK: - OR Divider

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.themeBorder)
                .frame(height: 1)

            Text("OR")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.themeTextTertiary)

            Rectangle()
                .fill(Color.themeBorder)
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sign Up Button

    private var signUpButton: some View {
        Button(action: viewModel.openSignUp) {
            HStack(spacing: 6) {
                Text("회원가입")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.themeBlue)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .fill(Color.themeCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .stroke(Color.themeBlue, lineWidth: 1.5)
            )
        }
    }
}

#Preview {
    LoginView()
}
