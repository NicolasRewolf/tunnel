import SwiftUI

/// Screen router. Animates transitions between every top-level screen.
struct ContentView: View {
    let appState: AppState

    var body: some View {
        ZStack {
            currentScreen
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: appState.screen)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch appState.screen {
        case .onboarding:   OnboardingView(appState: appState)
        case .home:         HomeView(appState: appState)
        case .incomingCall: IncomingCallView(appState: appState)
        case .inCall:       InCallView(appState: appState)
        case .settings:     SettingsView(appState: appState)
        }
    }
}

#Preview {
    ContentView(appState: AppState.shared)
}
