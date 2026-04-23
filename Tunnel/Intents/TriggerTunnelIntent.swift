import AppIntents

/// The single action Tunnel exposes to the system.
/// Appears in:
///   - iOS Shortcuts app
///   - Back Tap (Réglages › Accessibilité › Toucher › Toucher au dos › Raccourci)
///   - Action Button (iPhone 15 Pro+)
///   - Spotlight
///
/// `openAppWhenRun` is intentionally `false`: CallKit owns the incoming-call UI,
/// including on a locked device. Setting this to `true` would flash the HomeView
/// behind the CallKit card and defeat the purpose of the migration.
struct TriggerTunnelIntent: AppIntent {
    static var title: LocalizedStringResource = "Déclencher Tunnel"
    static var description = IntentDescription(
        "Lance immédiatement un faux appel entrant."
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        try await CallKitManager.shared.reportIncomingCall(
            contactName: AppState.shared.config.contactName
        )
        return .result()
    }
}
