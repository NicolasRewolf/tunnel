import SwiftUI

@main
struct TunnelApp: App {
    init() {
        // Warm-up CXProvider before any intent can fire. Avoids a race where
        // the first trigger on a cold launch hits an uninitialized provider.
        _ = CallKitManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: AppState.shared)
        }
    }
}
