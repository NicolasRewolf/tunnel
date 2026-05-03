import AppIntents

/// Surfaces Tunnel's single action to Shortcuts, Back Tap, Action Button,
/// Spotlight, and Siri.
///
/// `\(.applicationName)` resolves to the bundle display name ("Untunnel"),
/// so phrases below become "Déclenche Untunnel", "Faux appel Untunnel", etc.
/// All `shortTitle` and intent titles use "Untunnel" verbatim to match what
/// the user sees on the Home Screen — searching Shortcuts for "untunnel"
/// must surface this action.
struct TunnelAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerTunnelIntent(),
            phrases: [
                "Déclenche \(.applicationName)",
                "Lance \(.applicationName)",
                "Faux appel \(.applicationName)",
                "Sortir du tunnel avec \(.applicationName)",
                "\(.applicationName) maintenant",
            ],
            shortTitle: "Déclencher Untunnel",
            systemImageName: "phone.fill"
        )
    }
}
