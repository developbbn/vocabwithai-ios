//
//  AuthManager.swift
//  VocabWithAI
//
//  Created by 오세빈 on 4/22/26.
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

        // 앱 시작 시 이미 로그인 상태면 리스너 시작
        if self.isLoggedIn {
            Task { @MainActor in
                WordRepository.shared.startListening()
            }
        }
    }

    // MARK: - Sign Up

    /// 이메일/비밀번호로 회원가입 + 닉네임을 Firebase Auth displayName 으로 설정.
    ///
    /// 흐름:
    /// 1. Firebase Auth 계정 생성
    /// 2. displayName 설정 (`createProfileChangeRequest`)
    /// 3. displayName 설정 실패 시 → 방금 만든 계정 자동 삭제 (좀비 계정 방지)
    ///
    /// - Parameters:
    ///   - email: 가입 이메일
    ///   - password: 가입 비밀번호
    ///   - nickname: 표시명 (앞뒤 공백 제거 후 저장)
    func signUp(email: String, password: String, nickname: String) async throws {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. 계정 생성
        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // 2. displayName 설정 - 실패 시 방금 만든 계정 롤백
        do {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = trimmedNickname
            try await changeRequest.commitChanges()
        } catch {
            // 닉네임 설정에 실패하면 계정이 좀비 상태가 되니까 즉시 삭제
            // createUser 직후라 reauthenticate 없이 delete 가능
            try? await result.user.delete()
            throw error
        }

        // 3. 로컬 상태 업데이트 - Auth.auth().currentUser 로 displayName 반영된 최신 user 가져옴
        await MainActor.run {
            self.currentUser = Auth.auth().currentUser
            self.isLoggedIn = true
            WordRepository.shared.startListening()
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isLoggedIn = true
            WordRepository.shared.startListening()
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            WordRepository.shared.stopListening()
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }

    // MARK: - Account Deletion (App Store Review Guideline 5.1.1(v) 요구사항)

    /// 계정과 모든 사용자 데이터를 영구 삭제.
    ///
    /// 흐름:
    /// 1. 비밀번호로 재인증 (Firebase Auth 정책상 필수)
    /// 2. Firestore 사용자 데이터 삭제 (Auth 삭제보다 반드시 먼저)
    /// 3. Firebase Auth 사용자 삭제
    /// 4. 로컬 상태 정리 → RootView 가 LoginView 로 자동 전환
    ///
    /// - Parameter password: 재인증용 현재 비밀번호
    /// - Throws: 재인증 실패(잘못된 비밀번호), Firestore 삭제 실패, Auth 삭제 실패 시 throw
    func deleteAccount(password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notLoggedIn
        }
        guard let email = user.email else {
            throw AuthError.missingEmail
        }

        let uid = user.uid

        // 1. 재인증 - 마지막 로그인 후 시간 지났을 수 있어 필수
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)

        // 2. Firestore 사용자 데이터 삭제 (반드시 Auth 삭제 전에)
        try await deleteFirestoreData(for: uid)

        // 3. Firebase Auth 사용자 영구 삭제
        try await user.delete()

        // 4. 로컬 상태 정리 - RootView 가 isLoggedIn 변경 감지해서 LoginView 로 전환
        await MainActor.run {
            WordRepository.shared.stopListening()
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }

    /// 사용자의 Firestore 데이터 전부 삭제.
    ///
    /// ⚠️ 현재 가정한 구조: Pattern A — `users/{uid}/{subcollection}/{docId}`
    /// 실제 Firestore 구조가 다르면 아래 `subcollectionNames` 배열만 수정.
    private func deleteFirestoreData(for uid: String) async throws {
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(uid)

        let subcollectionNames = ["words", "dailyStats", "dailyPhrases"]

        for name in subcollectionNames {
            try await deleteAllDocuments(in: userDocRef.collection(name))
        }

        try await userDocRef.delete()
    }

    /// 컬렉션 내 모든 문서를 batch 단위로 삭제 (대량 데이터 안전 처리).
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
