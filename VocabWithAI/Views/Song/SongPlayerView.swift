//
//  SongPlayerView.swift
//  VocabWithAI
//
//  Created on 2026-04-13
//

import SwiftUI
import YouTubePlayerKit

// MARK: - SongPlayerView

struct SongPlayerView: View {
    let song: Song
    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var player: YouTubePlayer
    @State private var currentTime: Double = 0
    @State private var currentCardId: String? = nil  // 카드 변경 여부 추적
    private var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init(song: Song) {
        self.song = song
        _player = StateObject(wrappedValue: YouTubePlayer(
            source: .video(id: song.youtubeID),
            configuration: .init(
                allowsInlineMediaPlayback: true
            )
        ))
    }

    private var currentCard: LyricCard? {
        song.cards
            .filter { $0.timestamp <= currentTime }
            .last
    }

    private var currentCardIndex: Int {
        song.cards.firstIndex(where: { $0.id == currentCardId }) ?? 0
    }

    @State private var showInfo = false
    /// 저장된 단어 ID 추적 — 칩 색상 변경에 사용
    @State private var savedWordIds: Set<String> = []

    /// HighlightWord를 type에 따라 서재에 저장
    private func saveToLibrary(_ hw: HighlightWord) {
        let chipId = hw.word
        guard !savedWordIds.contains(chipId) else { return }

        if hw.type == "phrase" {
            // 표현 탭 → DailyPhrase로 저장 (북마크)
            let phrase = DailyPhrase(
                japanese: hw.word,
                reading: hw.reading,
                meaning: hw.meaning,
                exampleSentence: "",
                contextUsage: "🎵 \(song.title) — \(song.artist)",
                aiInsight: nil
            )
            DailyPhraseViewModel.shared.saveBookmark(phrase)
            ToastManager.shared.show(lines: ["\(hw.word) 표현에 추가됐어요 📚"], duration: 2.0)
        } else {
            // 단어 탭 → WordRepository에 저장
            WordRepository.shared.registerWord(
                word: hw.word,
                meaning: hw.meaning,
                pronunciation: hw.reading,
                memo: "🎵 \(song.title) — \(song.artist)"
            )
            ToastManager.shared.show(lines: ["\(hw.word) 단어에 추가됐어요 ✅"], duration: 2.0)
        }
        savedWordIds.insert(chipId)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // 네비게이션 바 (유튜브 위)
                navBar
                    .padding(.horizontal, 8)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                // YouTubePlayerKit 뷰
                YouTubePlayerView(player)
                    .frame(height: 220)

                controlBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                Divider()

                cardArea
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            Task {
                if let time = try? await player.getCurrentTime() {
                    let seconds = time.converted(to: .seconds).value
                    // 카드가 바뀔 때만 State 업데이트 → 불필요한 리렌더 방지
                    let newCardId = song.cards.filter { $0.timestamp <= seconds }.last?.id
                    if newCardId != currentCardId {
                        currentTime = seconds
                        currentCardId = newCardId
                    }
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            songInfoSheet
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(10)
                    .contentShape(Rectangle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(song.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(song.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showInfo = true }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .padding(10)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Song Info Sheet
    private var songInfoSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 핸들
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 24)

            // 타이틀
            Text("곡 정보 & 학습 팁")
                .font(.system(size: 22, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            // 본문
            VStack(alignment: .leading, spacing: 12) {
                Text("가사 안의 주요 단어 및 표현을 볼 수 있어요.")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                HStack(spacing: 0) {
                    Text("파란 박스")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    Text("를 누르면 서재에 추가돼요.")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Control Bar
    private var controlBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                Text("핵심단어 (\(song.cards.count))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)

            Spacer()

            Text("ON-REPEAT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
        }
    }

    // MARK: - Card Area
    private var cardArea: some View {
        VStack(alignment: .center, spacing: 16) {
            if let card = currentCard {
                highlightedText(card.japanese, highlights: card.highlightWords)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Text(card.reading)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Text(card.meaning)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if !card.highlightWords.isEmpty {
                    highlightWordChips(card.highlightWords)
                }

                cardProgressIndicator

            } else {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.3))
                    Text("재생하면 핵심 표현이 나타나요")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .id(currentCardId ?? "none")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.4), value: currentCardId)
    }

    // MARK: - Card Progress Indicator
    private var cardProgressIndicator: some View {
        Text("\(currentCardIndex + 1) / \(song.cards.count)")
            .font(.system(size: 12))
            .foregroundColor(.gray.opacity(0.6))
            .padding(.top, 8)
    }
    private func highlightWordChips(_ words: [HighlightWord]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(words.indices, id: \.self) { i in
                    let w = words[i]
                    let isSaved = savedWordIds.contains(w.word)
                    let chipColor: Color = isSaved ? .green : .blue

                    Button(action: { saveToLibrary(w) }) {
                        VStack(spacing: 3) {
                            HStack(spacing: 4) {
                                Text(w.word)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(chipColor)
                                if isSaved {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                            Text(w.reading)
                                .font(.system(size: 11))
                                .foregroundColor(chipColor.opacity(0.7))
                            Text(w.meaning)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(chipColor.opacity(0.07))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(chipColor.opacity(isSaved ? 0.5 : 0.2), lineWidth: isSaved ? 1.5 : 1)
                        )
                    }
                    .animation(.easeInOut(duration: 0.2), value: isSaved)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.top, 4)
    }

    // MARK: - Highlighted Text
    private func highlightedText(_ text: String, highlights: [HighlightWord]) -> Text {
        var result = Text("")
        var remaining = text

        while !remaining.isEmpty {
            var earliest: (range: Range<String.Index>, word: String)? = nil
            for hw in highlights {
                if let range = remaining.range(of: hw.word) {
                    if earliest == nil || range.lowerBound < earliest!.range.lowerBound {
                        earliest = (range, hw.word)
                    }
                }
            }
            if let found = earliest {
                let before = String(remaining[remaining.startIndex..<found.range.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before).foregroundColor(.primary)
                }
                result = result + Text(found.word).foregroundColor(.blue).bold()
                remaining = String(remaining[found.range.upperBound...])
            } else {
                result = result + Text(remaining).foregroundColor(.primary)
                break
            }
        }
        return result
    }
}

// MARK: - Preview
struct SongPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SongPlayerView(song: Song(
                id: "preview",
                title: "ヒロイン",
                artist: "back number",
                thumbnailURL: "",
                youtubeURL: "https://youtu.be/eit6sIzS7g8",
                youtubeID: "eit6sIzS7g8",
                jlptLevel: "N3",
                isRecommended: true,
                cards: [
                    LyricCard(
                        id: "p1",
                        timestamp: 0,
                        japanese: "君の毎日に 僕は似合わないかな",
                        reading: "きみのまいにちに ぼくはにあわないかな",
                        meaning: "너의 매일에 나는 어울리지 않는 걸까",
                        highlightWords: [
                            HighlightWord(word: "毎日", reading: "まいにち", meaning: "매일", type: "word"),
                            HighlightWord(word: "似合う", reading: "にあう", meaning: "어울리다", type: "word")
                        ]
                    )
                ]
            ))
        }
    }
}
