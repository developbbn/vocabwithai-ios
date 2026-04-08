//
//  PromptManager.swift
//  VocabWithAI
//
//  Created on 2026-04-08
//

import Foundation

/// 단어/표현 프롬프트를 UserDefaults에 저장하고 불러오는 싱글톤 매니저.
/// - 커스텀 프롬프트가 저장되어 있으면 그걸 반환
/// - 없으면 GeminiService의 기본 프롬프트를 반환
class PromptManager {

    static let shared = PromptManager()
    private init() {}

    private let wordPromptKey   = "customWordPrompt"
    private let phrasePromptKey = "customPhrasePrompt"

    // MARK: - Word Prompt

    /// 저장된 단어 프롬프트를 반환. 없으면 nil
    func wordPrompt() -> String? {
        UserDefaults.standard.string(forKey: wordPromptKey)
    }

    /// 단어 프롬프트를 저장한다
    func saveWordPrompt(_ prompt: String) {
        UserDefaults.standard.set(prompt, forKey: wordPromptKey)
    }

    /// 단어 프롬프트를 기본값으로 초기화한다
    func resetWordPrompt() {
        UserDefaults.standard.removeObject(forKey: wordPromptKey)
    }

    // MARK: - Phrase Prompt

    /// 저장된 표현 프롬프트를 반환. 없으면 nil
    func phrasePrompt() -> String? {
        UserDefaults.standard.string(forKey: phrasePromptKey)
    }

    /// 표현 프롬프트를 저장한다
    func savePhrasePrompt(_ prompt: String) {
        UserDefaults.standard.set(prompt, forKey: phrasePromptKey)
    }

    /// 표현 프롬프트를 기본값으로 초기화한다
    func resetPhrasePrompt() {
        UserDefaults.standard.removeObject(forKey: phrasePromptKey)
    }
}
