//
//  ToastManager.swift
//  VocabWithAI
//
//  Created on 2026-03-07
//

import Foundation
import Combine
import SwiftUI

// MARK: - Toast 모델

/// 토스트 1개를 나타내는 모델.
/// - lines: 표시할 텍스트 줄 배열. 1개면 단일 라인, 여러 개면 멀티 라인
/// - duration: 표시 지속 시간 (초)
struct Toast: Identifiable {
    let id = UUID()
    let lines: [String]
    let duration: Double

    /// 단일 라인 편의 생성자
    init(_ message: String, duration: Double = 3.0) {
        self.lines = [message]
        self.duration = duration
    }

    /// 멀티 라인 생성자
    init(lines: [String], duration: Double = 3.0) {
        self.lines = lines.filter { !$0.isEmpty }
        self.duration = duration
    }
}

// MARK: - ToastManager

/// 토스트 큐를 관리하는 싱글톤.
/// - 큐 방식: 현재 토스트가 사라진 후 다음 토스트를 표시
/// - show(_:) : 단일 라인
/// - show(lines:) : 멀티 라인
class ToastManager: ObservableObject {

    static let shared = ToastManager()
    private init() {}

    /// 현재 표시 중인 토스트
    @Published var current: Toast? = nil

    /// 대기 중인 토스트 큐
    private var queue: [Toast] = []
    private var hideTask: DispatchWorkItem?

    // MARK: - Public

    /// 단일 라인 토스트 추가
    func show(_ message: String, duration: Double = 3.0) {
        enqueue(Toast(message, duration: duration))
    }

    /// 멀티 라인 토스트 추가
    func show(lines: [String], duration: Double = 3.0) {
        enqueue(Toast(lines: lines, duration: duration))
    }

    // MARK: - Private

    private func enqueue(_ toast: Toast) {
        DispatchQueue.main.async {
            self.queue.append(toast)
            if self.current == nil {
                self.showNext()
            }
        }
    }

    private func showNext() {
        guard !queue.isEmpty else { return }
        let toast = queue.removeFirst()
        current = toast

        hideTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.current = nil
                // 짧은 딜레이 후 다음 토스트
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.showNext()
                }
            }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
    }
}

// MARK: - ToastStackView

/// ContentView 최상단에 올려두는 토스트 렌더러.
/// ToastManager.current를 구독해 토스트를 표시한다.
struct ToastStackView: View {
    @ObservedObject private var manager = ToastManager.shared

    var body: some View {
        VStack {
            Spacer()
            if let toast = manager.current {
                toastBubble(toast)
                    .padding(.bottom, 90)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(toast.id) // 토스트 교체 시 애니메이션 트리거
            }
        }
        .animation(.easeInOut(duration: 0.25), value: manager.current?.id)
        .allowsHitTesting(false) // 토스트가 하위 뷰 터치 막지 않도록
    }

    private func toastBubble(_ toast: Toast) -> some View {
        VStack(spacing: 4) {
            ForEach(Array(toast.lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(index == 0
                          ? .system(size: 16, weight: .bold)
                          : .system(size: 14))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.78))
        .cornerRadius(16)
    }
}
