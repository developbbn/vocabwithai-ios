//
//  MultipleChoiceQuizViewModel.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import Foundation
import Combine

// MARK: - 퀴즈 모드
enum MultipleChoiceMode {
    case kanji          // 한자 보고 히라가나 선택
    case pronunciation  // 히라가나 보고 한자 선택
}

// MARK: - 퀴즈 문제
struct QuizQuestion {
    let word: Word          // 원본 단어
    let prompt: String      // 화면에 표시할 문제 텍스트
    let choices: [String]   // 선지 4개 (셔플됨)
    let answer: String      // 정답
}

// MARK: - MultipleChoiceQuizViewModel
class MultipleChoiceQuizViewModel: ObservableObject {

    // MARK: - Published
    @Published var questions: [QuizQuestion] = []
    @Published var currentIndex: Int = 0
    @Published var selectedChoice: String? = nil
    @Published var isAnswered: Bool = false
    @Published var isFinished: Bool = false
    @Published var correctCount: Int = 0
    @Published var answeredCount: Int = 0  // 실제로 답변한 문제 수

    /// 틀린 문제 목록 — 결과 화면 "틀린 문제 확인하기"에서 사용
    @Published var wrongQuestions: [QuizQuestion] = []

    // MARK: - Properties
    let mode: MultipleChoiceMode

    // MARK: - Init
    init(mode: MultipleChoiceMode) {
        self.mode = mode
        buildQuestions()
    }

    // MARK: - Computed
    var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var totalCount: Int { questions.count }

    var isCorrect: Bool {
        guard let selected = selectedChoice,
              let question = currentQuestion else { return false }
        return selected == question.answer
    }

    var questionText: String {
        switch mode {
        case .kanji:         return "이 단어의 히라가나 읽기는?"
        case .pronunciation: return "이 발음의 한자 표기는?"
        }
    }

    /// 결과 화면용 점수 문자열 (예: "18/20")
    var scoreText: String { "\(correctCount)/\(answeredCount)" }

    /// 정답률 (0.0 ~ 1.0)
    var accuracy: Double {
        guard answeredCount > 0 else { return 0 }
        return Double(correctCount) / Double(answeredCount)
    }

    /// 정답률에 따른 결과 멘트
    var resultTitle: String {
        switch accuracy {
        case 1.0:        return "완벽해요! 🎉"
        case 0.8...:     return "대단한 결과예요!"
        case 0.6...:     return "잘 하고 있어요!"
        default:         return "조금만 더 힘내요!"
        }
    }

    var resultSubtitle: String {
        switch accuracy {
        case 1.0:        return "모든 문제를 맞혔어요. 최고예요!"
        case 0.8...:     return "거의 완벽한 점수입니다. 조금만 더 힘내세요."
        case 0.6...:     return "절반 이상 맞혔어요. 복습하면 더 잘할 수 있어요!"
        default:         return "틀린 문제를 복습해 보세요. 분명 나아질 거예요!"
        }
    }

    // MARK: - Actions
    func select(_ choice: String) {
        guard !isAnswered else { return }
        selectedChoice = choice
        isAnswered = true
        answeredCount += 1

        if choice == currentQuestion?.answer {
            correctCount += 1
        } else {
            if let q = currentQuestion { wrongQuestions.append(q) }
        }

        // 선지 선택 시 단어 정보 토스트 표시
        if let w = currentQuestion?.word {
            var lines = [w.word]
            if !w.pronunciation.isEmpty { lines.append(w.pronunciation) }
            lines.append(w.meaning)
            ToastManager.shared.show(lines: lines, duration: 2.0)
        }
    }

    func next() {
        guard isAnswered else { return }
        DailyStatsManager.shared.incrementQuizCount()
        if currentIndex + 1 >= questions.count {
            isFinished = true
        } else {
            currentIndex += 1
            selectedChoice = nil
            isAnswered = false
        }
    }

    /// 현재까지 답변한 문제로 즉시 종료
    func finishEarly() {
        isFinished = true
    }

    func restart() {
        currentIndex = 0
        selectedChoice = nil
        isAnswered = false
        isFinished = false
        correctCount = 0
        answeredCount = 0
        wrongQuestions = []
        buildQuestions()
    }

    // MARK: - Private: 문제 생성
    private func buildQuestions() {
        let words = WordRepository.shared.words

        // quizData가 있는 단어만 필터
        let validWords = words.filter { $0.quizData != nil }.shuffled()

        questions = validWords.compactMap { word -> QuizQuestion? in
            guard let quizData = word.quizData else { return nil }

            switch mode {
            case .kanji:
                // 문제: 한자 표기, 선지: 히라가나 choices
                let choices = quizData.hiraganaChoices.shuffled()
                let answer = quizData.hiraganaChoices.first ?? ""
                return QuizQuestion(
                    word: word,
                    prompt: word.word,
                    choices: choices,
                    answer: answer
                )

            case .pronunciation:
                // 문제: 히라가나(발음), 선지: 한자 choices
                let choices = quizData.kanjiChoices.shuffled()
                let answer = quizData.kanjiChoices.first ?? ""
                let prompt = word.pronunciation.isEmpty ? word.word : word.pronunciation
                return QuizQuestion(
                    word: word,
                    prompt: prompt,
                    choices: choices,
                    answer: answer
                )
            }
        }
    }
}
