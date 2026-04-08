//
//  WordRepository.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import Foundation
import Combine

// MARK: - WordRepository
/// 단어 저장소 + 백그라운드 AI 작업을 담당하는 싱글톤
/// ViewModel이 아닌 Repository가 AI 작업 수명을 관리 → 뷰가 사라져도 작업 유지
class WordRepository: ObservableObject {

    // MARK: - Singleton
    static let shared = WordRepository()
    private init() {
        load()
    }

    // MARK: - Published State
    @Published private(set) var words: [Word] = []
    /// 현재 AI 생성 중인 단어 ID 집합. WordDetailView 로딩 표시에 사용
    @Published private(set) var loadingWordIds: Set<UUID> = []

    // MARK: - Private
    private let storageKey = "savedWords"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public: 단어 등록
    func registerWord(word: String, meaning: String, pronunciation: String, memo: String) {
        let newWord = Word(
            word: word,
            meaning: meaning,
            pronunciation: pronunciation,
            memo: memo,
            aiContent: nil
        )

        // 1. 즉시 저장
        words.append(newWord)
        save()
        print("✅ 단어 즉시 저장 완료: \(word)")

        // 일일 통계 카운트
        DispatchQueue.main.async {
            DailyStatsManager.shared.incrementWordCount()
        }

        // 2. 백그라운드 AI 생성
        generateAIContent(for: newWord)
    }

    // MARK: - Public: AI 콘텐츠 재생성
    /// aiContent, quizData를 초기화하고 AI를 다시 요청한다.
    /// WordDetailView 새로고침 버튼에서 호출
    func regenerateAIContent(for word: Word) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index].aiContent = nil
        words[index].quizData  = nil
        save()
        generateAIContent(for: words[index])
        print("🔄 AI 재생성 시작: \(word.word)")
    }

    // MARK: - Public: 단어 수정
    func updateWord(_ updated: Word) {
        guard let index = words.firstIndex(where: { $0.id == updated.id }) else { return }
        let wordChanged = words[index].word != updated.word

        // 단어가 바뀌면 AI 콘텐츠 초기화 후 재생성
        var wordToSave = updated
        if wordChanged {
            wordToSave.aiContent = nil
            wordToSave.quizData  = nil
        }

        words[index] = wordToSave
        save()
        print("✏️ 단어 수정 완료: \(updated.word)")

        if wordChanged {
            generateAIContent(for: wordToSave)
        }
    }

    // MARK: - Public: 단어 삭제
    func deleteWord(_ word: Word) {
        words.removeAll { $0.id == word.id }
        save()
    }

    func deleteAllWords() {
        words.removeAll()
        save()
    }

    func deleteWords(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Private: 백그라운드 AI 생성
    private func generateAIContent(for word: Word) {
        print("🔵 백그라운드 AI 생성 시작: \(word.word)")
        loadingWordIds.insert(word.id)

        GeminiService.shared.generateWordContent(for: word.word)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("🔴 AI 에러 (\(word.word)): \(error.localizedDescription)")
                }
                self?.loadingWordIds.remove(word.id)
            } receiveValue: { [weak self] result in
                guard let self else { return }
                print("🟢 AI 성공: \(word.word) / quizData: \(result.quizData != nil ? "✅" : "❌")")
                self.updateAIContent(wordId: word.id, result: result)
                self.loadingWordIds.remove(word.id)
                // 전역 토스트 표시 → 어떤 화면에 있어도 노출
                ToastManager.shared.show("「\(word.word)」 AI 분석 완료! ✨")
            }
            .store(in: &cancellables)
    }

    // MARK: - Private: AI 결과 업데이트
    private func updateAIContent(wordId: UUID, result: WordAIContent) {
        guard let index = words.firstIndex(where: { $0.id == wordId }) else { return }
        words[index].aiContent = result.aiContent
        words[index].quizData = result.quizData
        save()
        print("💾 AI 콘텐츠 업데이트: \(words[index].word)")
    }

    // MARK: - Private: UserDefaults 저장/로드
    private func save() {
        if let encoded = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Word].self, from: data) else { return }
        words = decoded
    }
}
