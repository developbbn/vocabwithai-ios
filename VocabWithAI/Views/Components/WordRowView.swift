//
//  WordRowView.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import SwiftUI

struct WordRowView: View {
    let word: Word
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        NavigationLink(destination: WordDetailView(word: word)) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(word.word)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(word.meaning)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: {
                showDeleteConfirm = true
            }) {
                Label("삭제", systemImage: "trash")
            }
        }
        .confirmationDialog("이 단어를 삭제하시겠어요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                onDelete()
            }
            Button("취소", role: .cancel) {}
        }
    }
}

// MARK: - Preview
struct WordRowView_Previews: PreviewProvider {
    static var previews: some View {
        WordRowView(
            word: Word(
                word: "Resilient",
                meaning: "회복력 있는, 탄력 있는",
                pronunciation: "/rɪˈzɪliənt/"
            ),
            onDelete: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
