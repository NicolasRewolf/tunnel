import AppIntents

struct TunnelAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerTunnelIntent(),
            phrases: [
                "Lance \(.applicationName)",
                "\(.applicationName) appelle-moi",
                "Sors-moi du tunnel avec \(.applicationName)"
            ],
            shortTitle: "Déclencher Tunnel",
            systemImageName: "phone.fill"
        )
    }
}
