//
//  RootView.swift
//  VocabWithAI
//
//  Created by 오세빈 on 4/26/26.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                ContentView()
            }
            else{
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoggedIn)

    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager.shared)
}
