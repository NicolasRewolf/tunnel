//
//  ContentView.swift
//  Tunnel
//
//  Created by Nicolas Doucet on 22/04/2026.
//

import SwiftUI

struct ContentView: View {
    let appState: AppState

    var body: some View {
        ZStack {
            currentScreen
        }
        .animation(.easeInOut(duration: 0.25), value: appState.screen)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch appState.screen {
        case .onboarding:
            OnboardingView(appState: appState)
                .transition(.opacity)
        case .home:
            HomeView(appState: appState)
                .transition(.opacity)
        case .incomingCall:
            IncomingCallView(appState: appState)
                .transition(.opacity)
        case .inCall:
            InCallView(appState: appState)
                .transition(.opacity)
        case .settings:
            SettingsView(appState: appState)
                .transition(.opacity)
        }
    }
}

#Preview {
    ContentView(appState: AppState.shared)
}
