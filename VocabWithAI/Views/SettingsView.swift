//
//  SettingsView.swift
//  VocabWithAI
//
//  Created on 2026-04-08
//

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
