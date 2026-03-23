//
//  LibraryView.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .background(Color(.systemGroupedBackground))
                    
                    // Tab Selector
                    tabSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .background(Color(.systemGroupedBackground))
                    
                    // Content based on selected tab
                    if viewModel.selectedTab == .word {
                        wordListSection
                    } else {
                        phraseListSection  // ← 추가
                    }
                }
                
                // AI 완료 토스트 제거 → ContentView 전역 토스트로 이동
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadPhrases()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Library")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.black)
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "단어",
                isSelected: viewModel.selectedTab == .word,
                action: { viewModel.selectedTab = .word }
            )
            
            TabButton(
                title: "표현",
                isSelected: viewModel.selectedTab == .expression,
                action: { viewModel.selectedTab = .expression }
            )
            
            Spacer()
        }
    }
    
    // MARK: - Word List Section
    private var wordListSection: some View {
        Group {
            if viewModel.words.isEmpty {
                emptyState(message: "저장된 단어가 없어요")
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.words) { word in
                            WordRowView(word: word, onDelete: {
                                viewModel.deleteWord(word)
                            })
                            
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Phrase List Section  ← 추가
    private var phraseListSection: some View {
        Group {
            if viewModel.phrases.isEmpty {
                emptyState(message: "북마크한 표현이 없어요")
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.phrases) { phrase in
                            PhraseRowView(phrase: phrase, onDelete: {
                                viewModel.deletePhrase(phrase)
                            })
                            
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private func emptyState(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text(message)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)
            
            Text("표현을 추가해보세요!")
                .font(.system(size: 15))
                .foregroundColor(.gray.opacity(0.7))
            
            Spacer()
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(width: 100)
    }
}

// MARK: - Phrase Row View  ← 추가
struct PhraseRowView: View {
    let phrase: DailyPhrase
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                // Japanese
                Text(phrase.japanese)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                // Reading + Meaning
                HStack(spacing: 8) {
                    Text(phrase.reading)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(phrase.meaning)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Bookmark Icon
            Image(systemName: "bookmark.fill")
                .font(.system(size: 16))
                .foregroundColor(.blue.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: {
                showDeleteConfirm = true
            }) {
                Label("삭제", systemImage: "trash")
            }
        }
        .confirmationDialog("이 표현을 삭제하시겠어요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                onDelete()
            }
            Button("취소", role: .cancel) {}
        }
    }
}

// MARK: - Preview
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
