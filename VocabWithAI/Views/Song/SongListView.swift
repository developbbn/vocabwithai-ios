//
//  SongListView.swift
//  VocabWithAI
//
//  Created on 2026-04-13
//

import SwiftUI

struct SongListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var songs: [Song] = []

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if songs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("등록된 노래가 없어요")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        headerBanner
                            .padding(.bottom, 20)

                        VStack(spacing: 12) {
                            ForEach(songs) { song in
                                NavigationLink(destination: SongPlayerView(song: song)) {
                                    SongRow(song: song)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
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
        .onAppear {
            songs = SongRepository.shared.songs
        }
    }

    // MARK: - Header Banner
    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.2, blue: 0.9), Color(red: 0.2, green: 0.1, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)

            HStack {
                Spacer()
                VStack {
                    Text("♪")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.08))
                    Spacer()
                }
            }
            .frame(height: 200)

            VStack(alignment: .leading, spacing: 6) {
                Text("CURATED FOR YOU")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1.5)
                Text("음악으로 배우는\n오늘의 어휘")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - SongRow
struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: song.thumbnailURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
            }
            .frame(width: 72, height: 72)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                Text(song.artist)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text("어휘 \(song.cards.count)개")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    if song.isRecommended {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("추천")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            Spacer()

            Text(song.jlptLevel)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
struct SongListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SongListView()
        }
    }
}
