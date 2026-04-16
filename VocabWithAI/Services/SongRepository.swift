//
//  SongRepository.swift
//  VocabWithAI
//
//  Created on 2026-04-13
//

import Foundation

class SongRepository {

    static let shared = SongRepository()
    private init() { load() }

    private(set) var songs: [Song] = []

    private func load() {
        guard let url = Bundle.main.url(forResource: "songs", withExtension: "JSON") ??
                        Bundle.main.url(forResource: "songs", withExtension: "json") else {
            print("⚠️ songs.json 번들에서 찾을 수 없음 → Xcode에서 Target Membership 체크 필요")
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ songs.json 파일 읽기 실패")
            return
        }
        do {
            songs = try JSONDecoder().decode([Song].self, from: data)
            print("🎵 노래 \(songs.count)곡 로드 완료")
        } catch {
            print("❌ songs.json 디코딩 실패: \(error)")
        }
    }
}
