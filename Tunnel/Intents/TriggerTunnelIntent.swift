import AppIntents

struct TriggerTunnelIntent: AppIntent {
    static var title: LocalizedStringResource = "Déclencher Tunnel"
    static var description = IntentDescription("Lance immédiatement un faux appel entrant.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.triggerFakeCallNow()
        return .result()
    }
}
