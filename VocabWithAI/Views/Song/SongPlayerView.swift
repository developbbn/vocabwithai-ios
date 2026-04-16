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
        song.cards.firstIndex(where: { $0.id == currentCard?.id }) ?? 0
    }

    @State private var showInfo = false

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
                    currentTime = time.converted(to: .seconds).value
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            songInfoSheet
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: 22, weight: .bold))
                    Text(song.artist)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(song.jlptLevel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.top, 24)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("수록 단어 \(song.cards.count)개")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)

                ForEach(song.cards) { card in
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%d:%02d", Int(card.timestamp) / 60, Int(card.timestamp) % 60))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 36, alignment: .leading)
                        Text(card.japanese)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
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

                cardProgressDots

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
        .id(currentCard?.id ?? "none")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.4), value: currentCard?.id)
    }

    // MARK: - Highlight Word Chips
    private func highlightWordChips(_ words: [HighlightWord]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(words.indices, id: \.self) { i in
                    let w = words[i]
                    VStack(spacing: 3) {
                        Text(w.word)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                        Text(w.reading)
                            .font(.system(size: 11))
                            .foregroundColor(.blue.opacity(0.7))
                        Text(w.meaning)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.07))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.top, 4)
    }

    // MARK: - Card Progress Dots
    private var cardProgressDots: some View {
        HStack(spacing: 6) {
            ForEach(song.cards.indices, id: \.self) { idx in
                Circle()
                    .fill(idx <= currentCardIndex ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut, value: currentCardIndex)
            }
        }
        .padding(.top, 16)
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
                            HighlightWord(word: "毎日", reading: "まいにち", meaning: "매일"),
                            HighlightWord(word: "似合う", reading: "にあう", meaning: "어울리다")
                        ]
                    )
                ]
            ))
        }
    }
}
