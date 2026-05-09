import SwiftUI

/// Screen router. Animates transitions between every top-level screen.
/// The incoming-call ring phase is owned by CallKit (system UI), not this router.
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
        // Onboarding and Settings are presented as swipe-dismissible
        // sheets from HomeView; the underlying view is always Home so the
        // user can swipe them down to reveal it. Only `.inCall` is a
        // genuinely separate full-screen takeover (CallKit-driven).
        switch appState.screen {
        case .home, .onboarding, .settings:
            HomeView(appState: appState)
        case .inCall:
            InCallView(appState: appState)
        }
    }
}

#Preview {
    ContentView(appState: AppState.shared)
}
