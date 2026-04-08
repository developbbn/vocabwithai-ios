//
//  ContentView.swift
//  VocabWithAI
//
//  Created on 2026-01-27
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject private var toastManager = ToastManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        VStack {
                            Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                                .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                            Text("홈")
                        }
                    }
                    .tag(0)

                LibraryView()
                    .tabItem {
                        VStack {
                            Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                            Text("서재")
                        }
                    }
                    .tag(1)

                NavigationStack {
                    SearchView()
                }
                    .tabItem {
                        VStack {
                            Image(systemName: "magnifyingglass")
                            Text("검색")
                        }
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        VStack {
                            Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                            Text("설정")
                        }
                    }
                    .tag(3)
            }
            .accentColor(.blue)

            // 전역 토스트 오버레이 - 어떤 탭에 있어도 항상 최상단에 표시
            ToastView(message: toastManager.message, isShowing: $toastManager.isShowing)
                .padding(.bottom, 80) // 탭바 위에 띄우기
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
