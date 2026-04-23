import AppIntents

/// Surfaces Tunnel's single action to Shortcuts, Back Tap, Action Button, and Spotlight.
struct TunnelAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerTunnelIntent(),
            phrases: [
                "Déclenche \(.applicationName)",
                "Lance \(.applicationName)",
                "\(.applicationName) appelle-moi"
            ],
            shortTitle: "Déclencher Tunnel",
            systemImageName: "phone.fill"
        )
    }
}
