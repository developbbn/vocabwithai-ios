//
//  SongPlayerView.swift
//  VocabWithAI
//
//  Created on 2026-04-13
//

import SwiftUI
import WebKit

// MARK: - SongPlayerView

struct SongPlayerView: View {
    let song: Song
    @Environment(\.presentationMode) private var presentationMode

    /// 현재 재생 시간 (초). YouTubePlayerView에서 업데이트
    @State private var currentTime: Double = 0
    @State private var isPlaying: Bool = false

    /// 현재 시간에 해당하는 카드
    private var currentCard: LyricCard? {
        song.cards
            .filter { $0.timestamp <= currentTime }
            .last
    }

    /// 다음 등장할 카드 인덱스 (진행 표시용)
    private var currentCardIndex: Int {
        song.cards.firstIndex(where: { $0.id == currentCard?.id }) ?? 0
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // YouTube 플레이어
                YouTubePlayerView(
                    youtubeID: song.youtubeID,
                    currentTime: $currentTime,
                    isPlaying: $isPlaying
                )
                .frame(height: 240)

                // 핵심단어 칩 + ON-REPEAT 배지
                controlBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                Divider()

                // 가사 카드 영역
                cardArea
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Spacer()
            }
        }
        .overlay(alignment: .topLeading) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .contentShape(Rectangle())
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Control Bar
    private var controlBar: some View {
        HStack {
            // 핵심단어 칩
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

            // ON-REPEAT 배지
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
                // 일본어 가사 (핵심 단어 강조)
                highlightedText(card.japanese, highlights: card.highlightWords)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .animation(.easeInOut(duration: 0.3), value: card.id)

                // 히라가나 읽기
                Text(card.reading)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                // 한국어 번역
                Text(card.meaning)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // 핵심 단어 칩
                if !card.highlightWords.isEmpty {
                    highlightWordChips(card.highlightWords)
                }

                // 카드 진행 도트
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

// MARK: - YouTubePlayerView

/// WKWebView 기반 YouTube IFrame 플레이어.
/// JavaScript 폴링으로 현재 재생 시간을 2초마다 업데이트한다.
struct YouTubePlayerView: UIViewRepresentable {
    let youtubeID: String
    @Binding var currentTime: Double
    @Binding var isPlaying: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let userScript = WKUserScript(
            source: """
            setInterval(function() {
                var player = document.getElementById('player');
                if (player && player.contentWindow) {
                    player.contentWindow.postMessage('{"event":"command","func":"getCurrentTime"}', '*');
                }
                if (window.ytPlayer) {
                    var t = window.ytPlayer.getCurrentTime();
                    window.webkit.messageHandlers.timeUpdate.postMessage(t);
                }
            }, 500);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(context.coordinator, name: "timeUpdate")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        * { margin:0; padding:0; }
        body { background:#000; }
        #player-container { width:100%; height:100vh; }
        </style>
        </head>
        <body>
        <div id="player-container">
            <div id="ytplayer"></div>
        </div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
        var ytPlayer;
        function onYouTubeIframeAPIReady() {
            ytPlayer = new YT.Player('ytplayer', {
                height: '100%',
                width: '100%',
                videoId: '\(youtubeID)',
                playerVars: {
                    'playsinline': 1,
                    'controls': 1,
                    'rel': 0,
                    'modestbranding': 1
                },
                events: {
                    'onStateChange': function(e) {
                        window.webkit.messageHandlers.timeUpdate.postMessage(ytPlayer.getCurrentTime());
                    }
                }
            });
        }
        setInterval(function() {
            if (ytPlayer && ytPlayer.getCurrentTime) {
                window.webkit.messageHandlers.timeUpdate.postMessage(ytPlayer.getCurrentTime());
            }
        }, 500);
        </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: YouTubePlayerView

        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            if message.name == "timeUpdate",
               let time = message.body as? Double {
                DispatchQueue.main.async {
                    self.parent.currentTime = time
                }
            }
        }
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
                youtubeURL: "https://www.youtube.com/watch?v=eit6sIzS7g8", // 누락된 파라미터 추가
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
