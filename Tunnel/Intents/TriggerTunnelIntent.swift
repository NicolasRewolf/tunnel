import AppIntents

/// The single action Tunnel exposes to the system.
/// Appears in:
///   - iOS Shortcuts app
///   - Back Tap (Réglages › Accessibilité › Toucher › Toucher au dos › Raccourci)
///   - Siri voice queries ("Dis Siri, lance Tunnel")
///   - Spotlight / Action button (iPhone 15 Pro+)
struct TriggerTunnelIntent: AppIntent {
    static var title: LocalizedStringResource = "Lancer un faux appel"
    static var description = IntentDescription(
        "Déclenche immédiatement un faux appel entrant dans Tunnel."
    )
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.triggerFakeCallNow()
        return .result()
    }
}
