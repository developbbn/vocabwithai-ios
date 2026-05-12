//
//  SignUpViewModel.swift
//  VocabWithAI
//
//  Created on 2026-04-22
//
//  회원가입 화면의 ViewModel.
//  Combine 파이프라인으로 닉네임/비밀번호 규칙 검증, 일치 여부, 폼 유효성을 자동 계산.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SignUpViewModel: ObservableObject {

    // MARK: - 입력값 (View가 양방향 바인딩)
    @Published var nickname: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirm: String = ""

    // MARK: - UI 상태
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPassword: Bool = false
    @Published var showPasswordConfirm: Bool = false

    // MARK: - 파생 상태 (Combine으로 자동 계산)
    @Published private(set) var isNicknameValid: Bool = false
    @Published private(set) var hasMinLength: Bool = false
    @Published private(set) var hasLetter: Bool = false
    @Published private(set) var hasDigit: Bool = false
    @Published private(set) var isPasswordValid: Bool = false
    @Published private(set) var isPasswordMatched: Bool = false
    @Published private(set) var isFormValid: Bool = false

    // MARK: - 의존성
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(authManager: AuthManager = .shared) {
        self.authManager = authManager
        bindNicknameValidation()
        bindPasswordRules()
        bindPasswordMatch()
        bindFormValidation()
    }

    // MARK: - Combine 파이프라인

    /// 닉네임 입력 → 2~20자 검증 (앞뒤 공백 제거 후 카운트)
    private func bindNicknameValidation() {
        $nickname
            .map { input in
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                return (2...20).contains(trimmed.count)
            }
            .removeDuplicates()
            .assign(to: &$isNicknameValid)
    }

    /// 비밀번호 입력 → 각 규칙별 충족 여부 자동 계산
    private func bindPasswordRules() {
        // 8자 이상
        $password
            .map { $0.count >= 8 }
            .removeDuplicates()
            .assign(to: &$hasMinLength)

        // 영문 포함
        $password
            .map { $0.range(of: "[A-Za-z]", options: .regularExpression) != nil }
            .removeDuplicates()
            .assign(to: &$hasLetter)

        // 숫자 포함
        $password
            .map { $0.range(of: "[0-9]", options: .regularExpression) != nil }
            .removeDuplicates()
            .assign(to: &$hasDigit)

        // 세 규칙 모두 만족
        Publishers.CombineLatest3($hasMinLength, $hasLetter, $hasDigit)
            .map { $0 && $1 && $2 }
            .removeDuplicates()
            .assign(to: &$isPasswordValid)
    }

    /// 비밀번호와 확인 필드 일치 여부
    private func bindPasswordMatch() {
        Publishers.CombineLatest($password, $passwordConfirm)
            .map { password, confirm in
                !confirm.isEmpty && password == confirm
            }
            .removeDuplicates()
            .assign(to: &$isPasswordMatched)
    }

    /// 전체 폼 유효성 (닉네임 + 이메일 + 비밀번호 규칙 + 비밀번호 일치)
    private func bindFormValidation() {
        Publishers.CombineLatest4($isNicknameValid, $email, $isPasswordValid, $isPasswordMatched)
            .map { nicknameValid, email, passwordValid, passwordMatched in
                nicknameValid && !email.isEmpty && passwordValid && passwordMatched
            }
            .removeDuplicates()
            .assign(to: &$isFormValid)
    }

    // MARK: - Actions

    /// 회원가입 시도
    func signUp() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authManager.signUp(
                    email: email,
                    password: password,
                    nickname: nickname
                )
            } catch {
                errorMessage = errorDescription(for: error)
            }
            isLoading = false
        }
    }

    func togglePasswordVisibility() {
        showPassword.toggle()
    }

    func togglePasswordConfirmVisibility() {
        showPasswordConfirm.toggle()
    }

    // MARK: - Error Mapping

    private func errorDescription(for error: Error) -> String {
        let nsError = error as NSError
        let code = AuthErrorCode(rawValue: nsError.code)

        switch code {
        case .emailAlreadyInUse:
            return "이미 가입된 이메일입니다."
        case .invalidEmail:
            return "이메일 형식이 올바르지 않습니다."
        case .weakPassword:
            return "비밀번호가 너무 약합니다. 다시 설정해주세요."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        default:
            return "회원가입에 실패했습니다. 다시 시도해주세요."
        }
    }
}
