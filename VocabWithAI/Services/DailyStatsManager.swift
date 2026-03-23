//
//  DailyStatsManager.swift
//  VocabWithAI
//
//  Created on 2026-03-10
//

import Foundation
import Combine

class DailyStatsManager: ObservableObject {

    static let shared = DailyStatsManager()
    private init() {
        resetIfNewDay()
    }

    // MARK: - Published
    @Published private(set) var wordCount: Int = 0
    @Published private(set) var quizCount: Int = 0
    @Published private(set) var expressionDone: Bool = false

    // MARK: - UserDefaults Keys
    private let wordCountKey    = "daily_wordCount"
    private let quizCountKey    = "daily_quizCount"
    private let expressionKey   = "daily_expressionDone"
    private let lastDateKey     = "daily_lastDate"

    // MARK: - Public Actions
    func incrementWordCount() {
        wordCount += 1
        UserDefaults.standard.set(wordCount, forKey: wordCountKey)
    }

    func incrementQuizCount() {
        quizCount += 1
        UserDefaults.standard.set(quizCount, forKey: quizCountKey)
    }

    func resetData() {
        wordCount      = 0
        quizCount      = 0
        expressionDone = false
        UserDefaults.standard.set(0,     forKey: wordCountKey)
        UserDefaults.standard.set(0,     forKey: quizCountKey)
        UserDefaults.standard.set(false, forKey: expressionKey)
        UserDefaults.standard.removeObject(forKey: lastDateKey)
        print("🗑️ 일일 통계 수동 리셋 완료")
    }

    func markExpressionDone() {
        guard !expressionDone else { return }
        expressionDone = true
        UserDefaults.standard.set(true, forKey: expressionKey)
    }

    // MARK: - 날짜 체크 & 리셋
    private func resetIfNewDay() {
        let today = todayString()
        let last  = UserDefaults.standard.string(forKey: lastDateKey) ?? ""

        if today != last {
            // 날짜 바뀜 → 전체 초기화
            wordCount      = 0
            quizCount      = 0
            expressionDone = false
            UserDefaults.standard.set(0,     forKey: wordCountKey)
            UserDefaults.standard.set(0,     forKey: quizCountKey)
            UserDefaults.standard.set(false, forKey: expressionKey)
            UserDefaults.standard.set(today, forKey: lastDateKey)
            print("🔄 일일 통계 초기화: \(today)")
        } else {
            // 같은 날 → 저장된 값 로드
            wordCount      = UserDefaults.standard.integer(forKey: wordCountKey)
            quizCount      = UserDefaults.standard.integer(forKey: quizCountKey)
            expressionDone = UserDefaults.standard.bool(forKey: expressionKey)
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
