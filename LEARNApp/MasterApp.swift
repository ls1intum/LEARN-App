//
//  MasterApp.swift
//  MasterApp
//
//  Created by Minkyoung Park on 26.05.25.
//

import SwiftUI

@main
struct MasterApp: App {
    @StateObject private var appState = AppState()
    @State private var showMainTab = false
    
    init() {
    }

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn || showMainTab {
                MainTabView()
                    .environmentObject(appState)
                    .task  { await appState.bootstrap() }
            } else {
                OnboardingView(showMainTab: $showMainTab)
                    .environmentObject(appState)
            }
        }
    }
}
