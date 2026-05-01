//
//  VocabWithAIApp.swift
//  VocabWithAI
//
//  Created on 2026-01-27
//

import SwiftUI
import FirebaseCore

@main
struct VocabWithAIApp: App {

    
    init() {
        FirebaseApp.configure() //파이어베이스 초기화
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AuthManager.shared)
        }
    }
}
