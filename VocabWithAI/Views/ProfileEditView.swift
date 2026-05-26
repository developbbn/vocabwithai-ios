//
//  ProfileEditView.swift
//  VocabWithAI
//
//  Created on 2026-05-12
//
//  설정 > 닉네임 수정 화면.
//

import SwiftUI
import FirebaseAuth

struct ProfileEditView: View {

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    // MARK: - Constants

    private let maxLength = 12

    // MARK: - Validation

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 길이 검증: 2~12자
    private var isLengthValid: Bool {
        (2...maxLength).contains(trimmedNickname.count)
    }

    /// 문자 검증: 한글, 영문, 숫자만 (특수문자/공백 불허)
    private var isCharacterValid: Bool {
        guard !trimmedNickname.isEmpty else { return false }
        let pattern = "^[가-힣A-Za-z0-9]+$"
        return trimmedNickname.range(of: pattern, options: .regularExpression) != nil
    }

    private var hasChanges: Bool {
        trimmedNickname != (authManager.currentUser?.displayName ?? "")
    }

    private var canSave: Bool {
        isLengthValid && isCharacterValid && hasChanges && !isSaving
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 본문 타이틀
                    Text("새로운 닉네임을\n입력해주세요")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 20)

                    // 입력 필드
                    inputField

                    // 검증 체크리스트
                    validationChecklist

                    if let errorMessage {
                        errorBanner(message: errorMessage)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            // 하단 고정 저장 버튼
            saveButton
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.top, 8)
                .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("닉네임 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { Task { await performSave() } }) {
                    Text("완료")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canSave ? .blue : .gray.opacity(0.5))
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            nickname = authManager.currentUser?.displayName ?? ""
            // 진입 시 자동 포커스 (전환 애니메이션 충돌 방지 위해 약간 지연)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
        .onChange(of: nickname) { newValue in
            // 12자 초과 입력 차단
            if newValue.count > maxLength {
                nickname = String(newValue.prefix(maxLength))
            }
        }
    }

    // MARK: - Input Field

    private var inputField: some View {
        HStack(spacing: 8) {
            TextField("닉네임 입력", text: $nickname)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .disabled(isSaving)

            // 글자 수 카운터
            Text("\(nickname.count)/\(maxLength)")
                .font(.system(size: 13))
                .foregroundColor(.gray)

            // 클리어 버튼 (텍스트 있을 때만)
            if !nickname.isEmpty {
                Button(action: { nickname = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isFocused ? Color.blue : Color.gray.opacity(0.25),
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    // MARK: - Validation Checklist

    private var validationChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            validationRow(text: "2~\(maxLength)자 이내", isValid: isLengthValid)
            validationRow(text: "한글, 영문, 숫자만 사용 가능", isValid: isCharacterValid)
        }
    }

    private func validationRow(text: String, isValid: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isValid ? .green : .gray.opacity(0.4))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(isValid ? .green : .gray.opacity(0.5))
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
        .cornerRadius(10)
    }

    // MARK: - Save Button (Bottom)

    private var saveButton: some View {
        Button(action: { Task { await performSave() } }) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }
                Text(isSaving ? "저장 중..." : "저장하기")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(canSave ? Color.black : Color.gray.opacity(0.35))
            .cornerRadius(16)
        }
        .disabled(!canSave)
        .animation(.easeInOut(duration: 0.15), value: canSave)
    }

    // MARK: - Actions

    @MainActor
    private func performSave() async {
        guard canSave else { return }

        errorMessage = nil
        isSaving = true
        isFocused = false  // 키보드 내림

        do {
            try await authManager.updateNickname(trimmedNickname)
            // 성공 → 즉시 뒤로 가기 (SettingsView 프로필 카드가 자동 갱신됨)
            dismiss()
        } catch {
            errorMessage = humanReadableError(error as NSError)
        }

        isSaving = false
    }

    private func humanReadableError(_ error: NSError) -> String {
        guard error.domain == AuthErrorDomain else {
            return "변경에 실패했습니다. 잠시 후 다시 시도해주세요."
        }

        switch error.code {
        case AuthErrorCode.networkError.rawValue:
            return "네트워크 연결을 확인해주세요."
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return "보안을 위해 다시 로그인 후 시도해주세요."
        default:
            return "변경에 실패했습니다. (오류 \(error.code))"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileEditView()
            .environmentObject(AuthManager.shared)
    }
}
