//
//  SettingsView.swift
//  VocabWithAI
//
//  Created on 2026-04-08
//

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("프롬프트 편집") {
                    NavigationLink(destination: PromptEditView(type: .word)) {
                        Label("단어 프롬프트", systemImage: "textformat.abc")
                    }
                    NavigationLink(destination: PromptEditView(type: .phrase)) {
                        Label("표현 프롬프트", systemImage: "text.bubble")
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}

// MARK: - PromptEditView

/// 단어/표현 프롬프트를 직접 편집하는 화면.
/// - 저장된 커스텀 프롬프트가 있으면 그걸 초기값으로 표시
/// - 없으면 GeminiService의 기본 프롬프트를 초기값으로 표시
/// - 저장하면 PromptManager를 통해 UserDefaults에 영속 저장
/// - 기본값으로 되돌리기 시 저장된 커스텀 프롬프트 삭제
struct PromptEditView: View {

    enum PromptType {
        case word
        case phrase

        var title: String {
            switch self {
            case .word:   return "단어 프롬프트"
            case .phrase: return "표현 프롬프트"
            }
        }

        /// 현재 저장된 커스텀 프롬프트. 없으면 기본값 반환
        var currentPrompt: String {
            switch self {
            case .word:
                return PromptManager.shared.wordPrompt() ?? GeminiService.defaultWordPrompt
            case .phrase:
                return PromptManager.shared.phrasePrompt() ?? GeminiService.defaultPhrasePrompt
            }
        }

        var placeholder: String {
            switch self {
            case .word:   return "{word} 는 단어 플레이스홀더예요. 반드시 포함해주세요."
            case .phrase: return "{seed} 는 랜덤 시드 플레이스홀더예요. 포함을 권장해요."
            }
        }
    }

    let type: PromptType
    @Environment(\.dismiss) private var dismiss
    @State private var promptText = ""
    @State private var showResetConfirm = false
    @State private var showSavedToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 안내 텍스트
            Text(type.placeholder)
                .font(.system(size: 13))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.07))

            // 프롬프트 편집 TextEditor
            TextEditor(text: $promptText)
                .font(.system(size: 14))
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))

            // 저장 버튼
            Button(action: save) {
                Text("저장")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("기본값으로") {
                    showResetConfirm = true
                }
                .foregroundColor(.red)
                .font(.system(size: 14))
            }
        }
        .onAppear {
            promptText = type.currentPrompt
        }
        .confirmationDialog("기본 프롬프트로 되돌릴까요?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("기본값으로 되돌리기", role: .destructive) {
                reset()
            }
            Button("취소", role: .cancel) {}
        }
        .overlay(alignment: .bottom) {
            if showSavedToast {
                Text("저장됐어요 ✓")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(20)
                    .padding(.bottom, 80)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSavedToast)
    }

    // MARK: - Actions

    private func save() {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch type {
        case .word:   PromptManager.shared.saveWordPrompt(trimmed)
        case .phrase: PromptManager.shared.savePhrasePrompt(trimmed)
        }

        // 토스트 표시 후 자동 숨김
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSavedToast = false
        }
    }

    private func reset() {
        switch type {
        case .word:
            PromptManager.shared.resetWordPrompt()
            promptText = GeminiService.defaultWordPrompt
        case .phrase:
            PromptManager.shared.resetPhrasePrompt()
            promptText = GeminiService.defaultPhrasePrompt
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
