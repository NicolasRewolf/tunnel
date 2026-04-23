import SwiftUI

@main
struct TunnelApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(appState: AppState.shared)
        }
    }
}
