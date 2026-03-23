//
//  HomeViewModel.swift
//  VocabApp
//
//  Created on 2026-01-27
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userName: String = "젠인나오야"
    @Published var todayProgress: Double = 0.70
    @Published var studiedWordsCount: Int = 12
    @Published var remainingWordsCount: Int = 42
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Additional reactive bindings can be added here
    }
    
    // MARK: - Public Methods
    func updateProgress() {
        // Logic to update daily progress
    }
    
    func navigateToQuiz() {
        // Navigation logic for quiz
    }
    
    func navigateToLog() {
        // Navigation logic for activity log
    }
    
    func navigateToExpression() {
        // Navigation logic for expressions
    }
    
    func navigateToListening() {
        // Navigation logic for listening practice
    }
    
    var progressPercentage: String {
        "\(Int(todayProgress * 100))%"
    }
    
    var studiedWordsText: String {
        "연속 \(studiedWordsCount)일째"
    }
    
    var remainingWordsText: String {
        "단어 \(remainingWordsCount)개 완료"
    }
}
