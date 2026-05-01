//
//  LoginViewModel.swift
//  VocabWithAI
//
//  Created on 2026-04-22
//
//  로그인 화면의 ViewModel.
//  Combine 파이프라인으로 입력값 검증, 폼 유효성, 로그인 액션을 처리.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - 입력값 (View가 양방향 바인딩)
    @Published var email: String = ""
    @Published var password: String = ""

    // MARK: - UI 상태 (View가 읽기 전용으로 구독)
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPassword: Bool = false
    @Published var showSignUp: Bool = false
    @Published var showPasswordReset: Bool = false

    // MARK: - 파생 상태 (Combine 파이프라인으로 자동 계산)
    @Published private(set) var isFormValid: Bool = false

    // MARK: - 의존성
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(authManager: AuthManager = .shared) {
        self.authManager = authManager
        bindFormValidation()
    }

    // MARK: - Combine 파이프라인

    /// 이메일과 비밀번호 입력값을 묶어 폼 유효성 자동 계산.
    /// - 이메일: 비어있지 않음
    /// - 비밀번호: 6자 이상
    private func bindFormValidation() {
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                !email.isEmpty && password.count >= 6
            }
            .removeDuplicates()
            .assign(to: &$isFormValid)
    }

    // MARK: - Actions

    /// 로그인 시도
    func signIn() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authManager.signIn(email: email, password: password)
                // 성공 시: AuthManager.isLoggedIn 변경 → 앱 진입점에서 화면 전환 (Step 5)
            } catch {
                errorMessage = errorDescription(for: error)
            }
            isLoading = false
        }
    }

    /// 비밀번호 보기/숨기기 토글
    func togglePasswordVisibility() {
        showPassword.toggle()
    }

    /// 회원가입 화면으로 이동 트리거
    func openSignUp() {
        showSignUp = true
    }

    /// 비밀번호 재설정 트리거
    func openPasswordReset() {
        showPasswordReset = true
    }

    // MARK: - Error Mapping

    private func errorDescription(for error: Error) -> String {
        let nsError = error as NSError
        let code = AuthErrorCode(rawValue: nsError.code)

        switch code {
        case .invalidEmail:
            return "이메일 형식이 올바르지 않습니다."
        case .wrongPassword, .invalidCredential:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .userNotFound:
            return "존재하지 않는 계정입니다."
        case .userDisabled:
            return "비활성화된 계정입니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        default:
            return "로그인에 실패했습니다. 다시 시도해주세요."
        }
    }
}
