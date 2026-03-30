//
//  SearchView.swift
//  VocabWithAI
//
//  Created on 2026-03-30
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 검색바 영역 (흰색 배경)
                VStack {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .padding(.top, 50)
                .background(Color.white)

                // MARK: - 상태에 따라 다른 콘텐츠
                if viewModel.isSearching {
                    searchActiveContent
                } else {
                    idleContent
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
            .onTapGesture {
                isSearchFocused = false
            }
        }
    }

    // MARK: - 검색바
    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))

                TextField("단어 또는 표현 검색", text: $viewModel.searchText)
                    .font(.system(size: 16))
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit { viewModel.commitSearch() }

                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            if viewModel.isSearching {
                Button("취소") {
                    viewModel.searchText = ""
                    isSearchFocused = false
                }
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSearching)
    }

    // MARK: - 기본 상태 (검색어 없을 때)
    private var idleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                recentSearchesSection
                trendingSection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - 최근 검색어
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 검색어")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                if !viewModel.recentSearches.isEmpty {
                    Button("전체 삭제") {
                        viewModel.clearAllRecentSearches()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                }
            }

            if viewModel.recentSearches.isEmpty {
                // 빈 상태
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("최근 검색어가 없어요")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
                .background(Color.white)
                .cornerRadius(14)
            } else {
                // 칩 목록
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentSearches) { search in
                            Button(action: {
                                viewModel.selectRecentSearch(search.query)
                                isSearchFocused = true
                            }) {
                                Text(search.query)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 오늘의 인기 단어
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 인기 단어")
                .font(.system(size: 17, weight: .semibold))

            if viewModel.trendingWords.isEmpty {
                Text("등록된 단어가 없어요")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.trendingWords.enumerated()), id: \.element.id) { index, word in
                        TrendingWordRow(rank: index + 1, word: word)
                        if index < viewModel.trendingWords.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
            }
        }
    }

    // MARK: - 검색 활성 상태
    private var searchActiveContent: some View {
        VStack(spacing: 0) {
            // 필터 탭
            filterTabs
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            if viewModel.filteredResults.isEmpty {
                // 결과 없음
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("'\(viewModel.searchText)'에 대한 결과가 없어요")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                // 결과 목록
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.filteredResults) { result in
                            SearchResultRow(result: result, query: viewModel.searchText)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - 필터 탭
    private var filterTabs: some View {
        HStack(spacing: 8) {
            ForEach(SearchFilter.allCases, id: \.self) { filter in
                Button(action: { viewModel.selectedFilter = filter }) {
                    Text(filter.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.selectedFilter == filter ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedFilter == filter
                                ? Color.blue
                                : Color(.systemGray6)
                        )
                        .cornerRadius(20)
                }
            }
            Spacer()
        }
    }
}

// MARK: - 인기 단어 행
struct TrendingWordRow: View {
    let rank: Int
    let word: Word

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(rank == 1 ? .blue : .gray.opacity(0.5))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(word.word)
                        .font(.system(size: 16, weight: .semibold))
                    if !word.pronunciation.isEmpty {
                        Text(word.pronunciation)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                Text(word.meaning)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: rank == 1 ? "arrow.up.right" : "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(rank == 1 ? .blue : .gray.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - 검색 결과 행
struct SearchResultRow: View {
    let result: SearchResult
    let query: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    highlightedText(mainText, query: query)
                        .font(.system(size: 16, weight: .semibold))

                    // 타입 뱃지
                    Text(badgeLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(badgeColor.opacity(0.12))
                        .cornerRadius(6)
                }

                Text("뜻: \(subText)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(14)
    }

    // MARK: - 하이라이팅
    private func highlightedText(_ text: String, query: String) -> Text {
        let lower = text.lowercased()
        let queryLower = query.lowercased()

        guard let range = lower.range(of: queryLower) else {
            return Text(text)
        }

        let before  = String(text[text.startIndex..<range.lowerBound])
        let matched = String(text[range])
        let after   = String(text[range.upperBound...])

        return Text(before)
            + Text(matched).foregroundColor(.blue).bold()
            + Text(after)
    }

    private var mainText: String {
        switch result {
        case .word(let w):   return w.word
        case .phrase(let p): return p.japanese
        }
    }

    private var subText: String {
        switch result {
        case .word(let w):   return w.meaning
        case .phrase(let p): return p.meaning
        }
    }

    private var badgeLabel: String {
        switch result {
        case .word:   return "단어"
        case .phrase: return "표현"
        }
    }

    private var badgeColor: Color {
        switch result {
        case .word:   return .blue
        case .phrase: return .orange
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
