//
//  AuthManager.swift
//  VocabWithAI
//
//  Created by 오세빈 on 4/22/26.
//

import Foundation
import FirebaseAuth
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

    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isLoggedIn = true
            WordRepository.shared.startListening()
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isLoggedIn = true
            WordRepository.shared.startListening()
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            WordRepository.shared.stopListening()
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }
}
