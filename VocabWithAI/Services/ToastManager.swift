//
//  ToastManager.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import Foundation
import Combine

/// 앱 전역 토스트를 관리하는 싱글톤
/// ContentView 최상단에서 구독 → 어떤 화면에 있어도 토스트 표시 가능
class ToastManager: ObservableObject {

    // MARK: - Singleton
    static let shared = ToastManager()
    private init() {}

    // MARK: - Published State
    @Published var isShowing: Bool = false
    @Published var message: String = ""

    // MARK: - Private
    private var hideTask: DispatchWorkItem?

    // MARK: - Public
    func show(_ message: String, duration: Double = 3.0) {
        // 이전 예약된 숨김 취소 (연속 토스트 대응)
        hideTask?.cancel()

        DispatchQueue.main.async {
            self.message = message
            self.isShowing = true
        }

        let task = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.isShowing = false
            }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}
