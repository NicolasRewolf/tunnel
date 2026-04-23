import AppIntents

/// The single action Tunnel exposes to the system.
/// Appears in:
///   - iOS Shortcuts app
///   - Back Tap (Réglages › Accessibilité › Toucher › Toucher au dos › Raccourci)
///   - Action Button (iPhone 15 Pro+)
///   - Spotlight
struct TriggerTunnelIntent: AppIntent {
    static var title: LocalizedStringResource = "Déclencher Tunnel"
    static var description = IntentDescription(
        "Lance immédiatement un faux appel entrant."
    )
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.triggerFakeCallNow()
        return .result()
    }
}
