//
//  VocabWithAIApp.swift
//  VocabWithAI
//
//  Created on 2026-01-27
//

import SwiftUI

@main
struct VocabWithAIApp: App {
    // 앱 시작 시 WordRepository 초기화 (싱글톤 생성 + UserDefaults 로드)
    private let wordRepository = WordRepository.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
