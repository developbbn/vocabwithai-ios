//
//  SettingsView.swift
//  VocabWithAI
//
//  Created on 2026-04-08
//

import SwiftUI
import FirebaseAuth

// MARK: - Active Confirmation

private enum ActiveConfirmation: Identifiable {
    case logout
    case deleteAccount

    var id: Self { self }

    var title: String {
        switch self {
        case .logout:        return "정말 로그아웃 하시겠어요?"
        case .deleteAccount: return "정말 계정을 삭제하시겠어요?"
        }
    }

    var message: String {
        switch self {
        case .logout:        return "다시 로그인이 필요해요."
        case .deleteAccount: return "이 작업은 되돌릴 수 없으며, 모든 학습 데이터가 영구 삭제됩니다."
        }
    }

    var confirmLabel: String {
        switch self {
        case .logout:        return "로그아웃"
        case .deleteAccount: return "계속"
        }
    }

    var confirmColor: Color {
        switch self {
        case .logout:        return .black
        case .deleteAccount: return .red
        }
    }

    var sheetHeight: CGFloat {
        switch self {
        case .logout:        return 240
        case .deleteAccount: return 280
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var activeConfirmation: ActiveConfirmation?
    @State private var showPasswordSheet = false
    @State private var showProfileEdit = false
    @State private var notificationEnabled = false   // 항상 false (준비 중)
    @State private var infoMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        Text("설정")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        profileCard
                            .padding(.horizontal, 20)

                        Section_Notification
                        Section_Account
                        Section_AppInfo
                        Section_Danger

                        Spacer(minLength: 60)
                    }
                }
            }
            .navigationBarHidden(true)
            // 프로필 수정 화면으로 push
            .navigationDestination(isPresented: $showProfileEdit) {
                ProfileEditView()
            }
            // 단일 sheet (logout / delete) - 커스텀 바텀 시트
            .sheet(item: $activeConfirmation) { confirmation in
                ConfirmationBottomSheet(
                    title: confirmation.title,
                    message: confirmation.message,
                    confirmLabel: confirmation.confirmLabel,
                    confirmColor: confirmation.confirmColor,
                    onConfirm: {
                        handleConfirmationAction(for: confirmation)
                    }
                )
                .presentationDetents([.height(confirmation.sheetHeight)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            // 안내 알림
            .alert(
                "알림",
                isPresented: Binding(
                    get: { infoMessage != nil },
                    set: { if !$0 { infoMessage = nil } }
                )
            ) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(infoMessage ?? "")
            }
            // 에러 알림
            .alert(
                "오류",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            // 계정 삭제 비밀번호 입력 시트
            .sheet(isPresented: $showPasswordSheet) {
                AccountDeletionSheet(isPresented: $showPasswordSheet)
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(avatarLetter)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(email)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 수정 버튼 → ProfileEditView 로 push
            Button(action: { showProfileEdit = true }) {
                Text("수정")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Sections

    private var Section_Notification: some View {
        SettingsSection(title: "알림") {
            SettingsCard {
                HStack(spacing: 14) {
                    IconBox(icon: "bell.fill",
                            foreground: .blue,
                            background: Color.blue.opacity(0.1))
                    Text("학습 알림")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    PreparingBadge()
                    Toggle("", isOn: $notificationEnabled)
                        .labelsHidden()
                        .disabled(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    private var Section_Account: some View {
        SettingsSection(title: "계정") {
            SettingsCard {
                Button(action: { activeConfirmation = .logout }) {
                    SettingsNavRowContent(
                        icon: "rectangle.portrait.and.arrow.right",
                        iconColor: .primary,
                        iconBackground: Color.gray.opacity(0.15),
                        title: "로그아웃",
                        titleColor: .primary,
                        chevronColor: .gray
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var Section_AppInfo: some View {
        SettingsSection(title: "앱 정보") {
            SettingsCard {
                HStack(spacing: 14) {
                    IconBox(icon: "info.circle.fill",
                            foreground: .gray,
                            background: Color.gray.opacity(0.15))
                    Text("버전")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(appVersion)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    private var Section_Danger: some View {
        SettingsSection(title: "위험 구역", titleColor: .red) {
            SettingsCard {
                Button(action: { activeConfirmation = .deleteAccount }) {
                    SettingsNavRowContent(
                        icon: "trash.fill",
                        iconColor: .red,
                        iconBackground: Color.red.opacity(0.1),
                        title: "계정 삭제",
                        titleColor: .red,
                        chevronColor: .red.opacity(0.7)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Computed Properties

    private var displayName: String {
        if let name = authManager.currentUser?.displayName, !name.isEmpty {
            return name
        }
        if let email = authManager.currentUser?.email {
            return String(email.prefix(while: { $0 != "@" }))
        }
        return "사용자"
    }

    private var email: String {
        authManager.currentUser?.email ?? ""
    }

    private var avatarLetter: String {
        String(displayName.prefix(1))
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    private func handleConfirmationAction(for confirmation: ActiveConfirmation) {
        activeConfirmation = nil

        switch confirmation {
        case .logout:
            handleLogout()
        case .deleteAccount:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showPasswordSheet = true
            }
        }
    }

    private func handleLogout() {
        do {
            try authManager.signOut()
        } catch {
            errorMessage = "로그아웃 중 오류가 발생했습니다. 다시 시도해주세요."
        }
    }
}

// MARK: - Confirmation Bottom Sheet

struct ConfirmationBottomSheet: View {

    let title: String
    let message: String
    let confirmLabel: String
    let confirmColor: Color
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("취소")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    Text(confirmLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(confirmColor)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Reusable Components

private struct SettingsSection<Content: View>: View {
    let title: String
    var titleColor: Color = .secondary
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(titleColor)
                .padding(.horizontal, 20)

            content()
                .padding(.horizontal, 20)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

private struct IconBox: View {
    let icon: String
    let foreground: Color
    let background: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(background)
            .frame(width: 38, height: 38)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(foreground)
            )
    }
}

private struct SettingsNavRowContent: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let titleColor: Color
    let chevronColor: Color

    var body: some View {
        HStack(spacing: 14) {
            IconBox(icon: icon, foreground: iconColor, background: iconBackground)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(titleColor)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(chevronColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct PreparingBadge: View {
    var body: some View {
        Text("준비 중")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .cornerRadius(8)
    }
}

// MARK: - Account Deletion Sheet

struct AccountDeletionSheet: View {

    @Binding var isPresented: Bool

    @State private var password: String = ""
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.red)
                        .padding(.top, 20)

                    VStack(spacing: 12) {
                        Text("계정을 영구 삭제합니다")
                            .font(.title2.bold())

                        Text("아래 항목들이 모두 삭제되며, 복구할 수 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("저장한 모든 단어", systemImage: "checkmark")
                        Label("학습 기록 및 통계", systemImage: "checkmark")
                        Label("오늘의 표현 기록", systemImage: "checkmark")
                        Label("계정 정보 (이메일)", systemImage: "checkmark")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("계속하려면 현재 비밀번호를 입력해주세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        SecureField("비밀번호", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .disabled(isDeleting)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: { Task { await performDeletion() } }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isDeleting ? "삭제 중..." : "계정 영구 삭제")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canDelete ? Color.red : Color.gray.opacity(0.5))
                        .cornerRadius(14)
                    }
                    .disabled(!canDelete)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("계정 삭제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                    .disabled(isDeleting)
                }
            }
            .interactiveDismissDisabled(isDeleting)
        }
    }

    private var canDelete: Bool {
        !password.isEmpty && !isDeleting
    }

    @MainActor
    private func performDeletion() async {
        errorMessage = nil
        isDeleting = true

        do {
            try await AuthManager.shared.deleteAccount(password: password)
        } catch {
            isDeleting = false
            errorMessage = humanReadableError(error as NSError)
        }
    }

    private func humanReadableError(_ error: NSError) -> String {
        guard error.domain == AuthErrorDomain else {
            return "삭제에 실패했습니다. 잠시 후 다시 시도해주세요."
        }

        switch error.code {
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return "비밀번호가 올바르지 않습니다."
        case AuthErrorCode.networkError.rawValue:
            return "네트워크 연결을 확인해주세요."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "잠시 후 다시 시도해주세요. (너무 많은 시도)"
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return "보안을 위해 다시 로그인 후 시도해주세요."
        case AuthErrorCode.userNotFound.rawValue:
            return "계정 정보를 찾을 수 없습니다."
        default:
            return "삭제에 실패했습니다. (오류 \(error.code))"
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthManager.shared)
    }
}
