//
//  AuthManager.swift
//  VocabWithAI
//
//  Created by 오세빈 on 4/22/26.
//  Updated on 2026-05-12 — 세션 격리 + 닉네임 수정 기능 추가
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false

    private init() {
        self.currentUser = Auth.auth().currentUser
        self.isLoggedIn = (Auth.auth().currentUser != nil)

        if self.isLoggedIn {
            Task { @MainActor in
                startAllUserListeners()
            }
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, nickname: String) async throws {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        do {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = trimmedNickname
            try await changeRequest.commitChanges()
        } catch {
            try? await result.user.delete()
            throw error
        }

        await MainActor.run {
            clearAllUserSessions()

            self.currentUser = Auth.auth().currentUser
            self.isLoggedIn = true

            startAllUserListeners()
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)

        await MainActor.run {
            clearAllUserSessions()

            self.currentUser = result.user
            self.isLoggedIn = true

            startAllUserListeners()
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()

        DispatchQueue.main.async {
            self.clearAllUserSessions()

            self.currentUser = nil
            self.isLoggedIn = false
        }
    }

    // MARK: - Update Profile (Nickname)

    /// Firebase Auth displayName 을 업데이트.
    /// 추후 프로필 사진(photoURL) 등 다른 프로필 필드 추가 시 이 메서드 확장.
    func updateNickname(_ nickname: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notLoggedIn
        }

        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = trimmed
        try await changeRequest.commitChanges()

        // 로컬 @Published 갱신 → SettingsView/HomeView 프로필 카드 자동 업데이트
        await MainActor.run {
            self.currentUser = Auth.auth().currentUser
        }

        print("✏️ 닉네임 변경 완료: \(trimmed)")
    }

    // MARK: - Account Deletion

    func deleteAccount(password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notLoggedIn
        }
        guard let email = user.email else {
            throw AuthError.missingEmail
        }

        let uid = user.uid

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)

        await MainActor.run {
            self.clearAllUserSessions()
        }

        try await deleteFirestoreData(for: uid)

        try await user.delete()

        await MainActor.run {
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }

    // MARK: - Session Management

    @MainActor
    private func startAllUserListeners() {
        WordRepository.shared.startListening()
        DailyPhraseViewModel.shared.startListening()
    }

    @MainActor
    private func clearAllUserSessions() {
        WordRepository.shared.stopListening()
        DailyPhraseViewModel.shared.clearSession()
        DailyStatsManager.shared.resetData()
    }

    // MARK: - Firestore Data Deletion

    private func deleteFirestoreData(for uid: String) async throws {
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(uid)

        let subcollectionNames = [
            "words",
            "dailyStats",
            "bookmarkedPhrases"
        ]

        for name in subcollectionNames {
            try await deleteAllDocuments(in: userDocRef.collection(name))
        }

        try await userDocRef.delete()
    }

    private func deleteAllDocuments(in collection: CollectionReference, batchSize: Int = 500) async throws {
        while true {
            let snapshot = try await collection.limit(to: batchSize).getDocuments()
            guard !snapshot.documents.isEmpty else { break }

            let batch = collection.firestore.batch()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()

            if snapshot.documents.count < batchSize { break }
        }
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case notLoggedIn
    case missingEmail

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:  return "로그인 상태가 아닙니다."
        case .missingEmail: return "계정 이메일을 확인할 수 없습니다."
        }
    }
}
