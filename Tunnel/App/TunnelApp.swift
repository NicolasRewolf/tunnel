import AppIntents
import SwiftUI

@main
struct TunnelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // Warm-up CXProvider before any intent can fire. Avoids a race where
        // the first trigger on a cold launch hits an uninitialized provider.
        _ = CallKitManager.shared

        // Force the system to (re)index our App Shortcuts on every launch.
        // Apple says static shortcuts are indexed automatically on first
        // launch, but in practice Spotlight's cache goes stale across iOS
        // updates, TestFlight reinstalls, and force-quits — leaving "Untunnel"
        // missing from the Shortcuts app's action picker for some users.
        // Calling this is a no-op when the index is already current and is
        // explicitly recommended by the App Intents docs.
        TunnelAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: AppState.shared)
        }
    }
}
