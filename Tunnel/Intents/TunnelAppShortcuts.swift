import AppIntents

/// Surfaces Tunnel's single action to Siri, Shortcuts, Back Tap, and Spotlight.
struct TunnelAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerTunnelIntent(),
            phrases: [
                "Lance \(.applicationName)",
                "Déclenche \(.applicationName)",
                "\(.applicationName) appelle-moi"
            ],
            shortTitle: "Lancer un faux appel",
            systemImageName: "phone.fill"
        )
    }
}
