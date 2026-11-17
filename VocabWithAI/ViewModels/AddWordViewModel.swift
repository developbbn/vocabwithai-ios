//
//  AddWordViewModel.swift
//  VocabWithAI
//
//  Created on 2026-02-03
//

import Foundation
import Combine

@MainActor
class AddWordViewModel: ObservableObject {

    // MARK: - Published Input (폼 상태만 관리)
    @Published var word: String = ""
    @Published var meaning: String = ""
    @Published var pronunciation: String = ""
    @Published var memo: String = ""

    // MARK: - Published Output
    @Published var isRegisterEnabled: Bool = false
    @Published var wordError: String? = nil
    @Published var meaningError: String? = nil
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var duplicateMessage: String = "텟"

    // MARK: - Dependency
    private let repository: WordRepository

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init (DI로 Repository 주입, 기본값은 shared)
    init(repository: WordRepository? = nil) {
        self.repository = repository ?? .shared
        setupBindings()
    }

    // MARK: - Combine Bindings
    private func setupBindings() {
        Publishers.CombineLatest3($word, $meaning, repository.$words)
            .map { word, meaning, words in
                !word.trimmingCharacters(in: .whitespaces).isEmpty &&
                !meaning.trimmingCharacters(in: .whitespaces).isEmpty &&
                !words.contains{ $0.word == word }
            }
            .assign(to: &$isRegisterEnabled)
        
        Publishers.CombineLatest($word, repository.$words)
            .map{ word, words in
                return words.contains{ $0.word == word.trimmingCharacters(in: .whitespaces) } ?
                "이미 등록된 단어입니다" : ""
            }
            .assign(to: &$duplicateMessage)
        

        $word
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                let trimmed = value.trimmingCharacters(in: .whitespaces)
                self?.wordError = trimmed.count > 50 ? "단어는 50자 이내로 입력해주세요." : nil
            }
            .store(in: &cancellables)

        $meaning
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                let trimmed = value.trimmingCharacters(in: .whitespaces)
                self?.meaningError = trimmed.count > 100 ? "뜻은 100자 이내로 입력해주세요." : nil
            }
            .store(in: &cancellables)

        $showToast
            .filter { $0 }
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.showToast = false }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    @MainActor
    func registerWord() {
        let trimmedWord = word.trimmingCharacters(in: .whitespaces)
        let trimmedMeaning = meaning.trimmingCharacters(in: .whitespaces)

        guard !trimmedWord.isEmpty, !trimmedMeaning.isEmpty else { return }

        // Repository에 등록 위임 (저장 + 백그라운드 AI 모두 Repository가 담당)
        repository.registerWord(
            word: trimmedWord,
            meaning: trimmedMeaning,
            pronunciation: pronunciation.trimmingCharacters(in: .whitespaces),
            memo: memo.trimmingCharacters(in: .whitespaces)
        )

        // 폼 초기화 + 토스트
        toastMessage = "저장 완료! AI 분석 중...\n(계속 단어를 등록할 수 있어요)"
        showToast = true
        resetForm()
    }

    func resetForm() {
        word = ""
        meaning = ""
        pronunciation = ""
        memo = ""
    }
}
