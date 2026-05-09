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
    // Title must match the bundle's display name ("Untunnel"): users who
    // search Shortcuts for the app name expect to find an action labelled
    // the same way.
    static var title: LocalizedStringResource = "Déclencher Untunnel"
    // categoryName + searchKeywords aident Spotlight et le picker Toucher
    // au dos à matcher l'intent même quand l'utilisateur cherche par
    // synonymes (« faux appel », « excuse », etc.).
    static var description = IntentDescription(
        "Lance immédiatement un faux appel entrant.",
        categoryName: "Untunnel",
        searchKeywords: [
            "faux appel",
            "untunnel",
            "sortir",
            "excuse",
            "discret",
            "appel entrant",
            "fake call",
        ]
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            try await CallKitManager.shared.reportIncomingCall(
                contactName: AppState.shared.activeProfile.contactName
            )
            // Donation post-succès : renforce le ranking Spotlight et la
            // promotion système (Toucher au dos, suggestions Siri). Best
            // effort — ne doit pas masquer la réussite si elle échoue.
            _ = try? await IntentDonationManager.shared.donate(intent: TriggerTunnelIntent())
            return .result()
        } catch {
            // Même libellés que le bouton d’accueil. Persistance si l’app n’était pas au 1er plan
            // (Raccourcis n’affiche que parfois le détail — voir Documentation/TriggerScenarios.md).
            let message = CallKitManager.userFacingMessage(for: error)
            AppState.shared.recordIntentTriggerFailure(message)
            throw error
        }
    }
}
