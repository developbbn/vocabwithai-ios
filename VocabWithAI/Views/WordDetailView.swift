//
//  WordDetailView.swift
//  VocabApp
//
//  Created on 2026-02-03
//

import SwiftUI

struct WordDetailView: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Word Header
                    wordHeader
                        .padding(.top, 80)
                    
                    // AI Content
                    if let aiContent = word.aiContent, !aiContent.isEmpty {
                        aiContentView(aiContent)
                    } else {
                        noAIContent
                    }
                    
                    // User Memo (있으면)
                    if !word.memo.isEmpty {
                        userMemoSection
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            
            // Custom Nav Bar
            VStack {
                customNavBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Custom Nav Bar
    private var customNavBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            Spacer()
        }
    }
    
    // MARK: - Word Header
    private var wordHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word.word)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.black)
            
            if !word.pronunciation.isEmpty {
                Text(word.pronunciation)
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            
            Text(word.meaning)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - AI Content View
    private func aiContentView(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("AI Learning")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            // iOS 15+ 마크다운 지원
            if #available(iOS 15.0, *) {
                Text(.init(content))
                    .font(.system(size: 16))
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
            } else {
                // iOS 14 이하 - 일반 텍스트
                Text(content)
                    .font(.system(size: 16))
                    .lineSpacing(6)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
            }
        }
    }
    
    // MARK: - No AI Content
    private var noAIContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("AI 학습 콘텐츠가 없습니다")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Text("단어 등록 시 AI가 자동으로 분석합니다")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - User Memo Section
    private var userMemoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("내 메모")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Text(word.memo)
                .font(.system(size: 16))
                .lineSpacing(6)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview
struct WordDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WordDetailView(word: Word(
            word: "慌てる",
            meaning: "당황하다",
            pronunciation: "あわてる",
            memo: "편의점에서 계산할 때 자주 쓰는 표현",
            aiContent: """
            ## 1. 한자 분석
            
            - **부수**: 忄 (심방변 - 마음 심)
            - **음독**: コウ
            - **훈독**: あわ・てる
            
            🔍 **[나노 분해: 12획]**
            
            마음이 엉망진창이 된 모습입니다.
            
            ## 2. 관련 단어
            
            1. **慌ただしい** (あわただしい) - 분주하다
            2. **大慌て** (おおあわて) - 매우 당황함
            
            ## 3. 실전 예문
            
            ### 1️⃣ 편의점 🏪
            
            お会計で、慌てなくても大丈夫ですよ。
            
            "계산할 때 당황하지 않으셔도 괜찮아요."
            """
        ))
    }
}
