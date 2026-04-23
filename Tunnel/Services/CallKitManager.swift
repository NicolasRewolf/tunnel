import CallKit
import OSLog

/// Single entry point for every CallKit interaction in Tunnel.
/// Compartmentalized by design: nothing else in the app imports CallKit.
///
/// Compliance rules hard-coded here. Each one is a signal to App Review that
/// this is a local simulation, not a VoIP client.
///
///  1. `UIBackgroundModes` includes `voip` — **required** by iOS for
///     `CXProvider` registration. Without it, `callservicesd` silently drops
///     the provider and `reportNewIncomingCall` never produces a UI.
///     This is a capability gate, not a feature claim: we still ship no
///     PushKit, no VoIP push entitlement, and no audio routing.
///  2. No PushKit, no `com.apple.developer.pushkit.unrestricted-voip`.
///     We never receive remote VoIP pushes.
///  3. `CXHandle.type = .generic` — never `.phoneNumber`.
///  4. `includesCallsInRecents = false` — nothing lands in the Phone app.
///  5. `ringtoneSound` left unset — the user's system ringtone plays.
///  6. No `provider(_:didActivate:)` — we never route audio through the
///     CallKit session.
///  7. No persistence of UUIDs or call history — `currentCallUUID` is
///     in-memory only and cleared on end / reset.
@MainActor
final class CallKitManager: NSObject {
    static let shared = CallKitManager()

    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "CallKitManager")
    private let provider: CXProvider
    private let callController = CXCallController()
    private var currentCallUUID: UUID?

    /// Debounce window for `reportIncomingCall`.
    /// Protects against rapid-fire triggers (Back Tap spam, user re-pressing
    /// because "rien ne se passe"): `maximumCallGroups = 1` would reject
    /// extras with `CXErrorCodeOutgoingCallFailed` silently, so we filter
    /// them here instead — returning cleanly rather than surfacing a
    /// cryptic system error to the user.
    private var lastReportAt: Date = .distantPast
    private static let minReportInterval: TimeInterval = 1.0

    private override init() {
        // The deprecated `init(localizedName:)` is a silent no-op on iOS 14+:
        // it accepts the string but never stores it, so the daemon registers
        // `localizedName=(null)` and immediately drops the XPC connection.
        // The no-arg init derives `localizedName` from CFBundleDisplayName
        // (pinned to "Untunnel" via INFOPLIST_KEY_CFBundleDisplayName).
        let config = CXProviderConfiguration()
        config.supportsVideo = false
        config.supportedHandleTypes = [.generic]            // rule 3
        config.maximumCallsPerCallGroup = 1
        config.maximumCallGroups = 1
        config.includesCallsInRecents = false               // rule 4
        // ringtoneSound intentionally left nil             // rule 5
        self.provider = CXProvider(configuration: config)
        super.init()
        self.provider.setDelegate(self, queue: nil)
    }

    // MARK: - Public API

    /// Reports a new incoming fake call to the system.
    /// CallKit takes over: native incoming-call UI (lock screen OK),
    /// system ringtone, vibration.
    ///
    /// Debounced: two calls < 1s apart collapse to one. If a call is already
    /// active (tracked via `currentCallUUID`), the request is skipped — the
    /// existing CallKit UI is still up.
    func reportIncomingCall(contactName: String) async throws {
        let now = Date()
        guard now.timeIntervalSince(lastReportAt) >= Self.minReportInterval else {
            logger.info("Debounced rapid-fire incoming call")
            return
        }
        guard currentCallUUID == nil else {
            logger.info("Ignored trigger: a call is already in progress")
            return
        }
        lastReportAt = now

        let uuid = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: contactName)  // rule 3
        update.localizedCallerName = contactName
        update.hasVideo = false
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false

        try await provider.reportNewIncomingCall(with: uuid, update: update)
        currentCallUUID = uuid                                              // rule 7: in-memory only
        logger.info("CallKit accepted incoming call \(uuid, privacy: .public)")
    }

    /// Maps a CallKit error (or any underlying Error) to a short French
    /// message suitable for a toast/alert. Detail stays in the log; the UI
    /// only needs a one-liner the user can act on.
    /// Static so other layers can call it without importing CallKit.
    nonisolated static func userFacingMessage(for error: Error) -> String {
        let ns = error as NSError
        if ns.domain == CXErrorDomainIncomingCall,
           let code = CXErrorCodeIncomingCallError.Code(rawValue: ns.code) {
            switch code {
            case .callUUIDAlreadyExists:
                return "Un appel est déjà en cours."
            case .filteredByBlockList, .filteredByDoNotDisturb:
                return "Bloqué par un réglage système (Ne pas déranger ou filtre)."
            default:
                break
            }
        }
        return "Impossible de lancer l'appel. Réessaye dans un instant."
    }

    /// Ends the currently-active fake call. Used by the "Raccrocher" button.
    /// If the `CXEndCallAction` transaction fails (daemon unresponsive,
    /// UUID no longer valid, …), we force the app out of `.inCall` ourselves
    /// so the user is never stranded on `InCallView` with no way out.
    func endActiveCall() {
        guard let uuid = currentCallUUID else { return }
        let transaction = CXTransaction(action: CXEndCallAction(call: uuid))
        callController.request(transaction) { error in
            guard let error else { return }
            // Singleton: no weak ref needed. Hop to main for UI teardown.
            Task { @MainActor in
                let manager = CallKitManager.shared
                manager.logger.error(
                    "CXEndCallAction failed: \(error.localizedDescription, privacy: .public) — forcing local teardown"
                )
                manager.currentCallUUID = nil
                AppState.shared.didEndCallKit()
            }
        }
    }
}

// MARK: - CXProviderDelegate

extension CallKitManager: CXProviderDelegate {
    nonisolated func providerDidReset(_ provider: CXProvider) {
        Task { @MainActor in
            self.currentCallUUID = nil
            AppState.shared.didEndCallKit()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Task { @MainActor in
            AppState.shared.didAnswerCallKit()
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task { @MainActor in
            self.currentCallUUID = nil
            AppState.shared.didEndCallKit()
            action.fulfill()
        }
    }

    // Rule 6: intentionally no `provider(_:didActivate:)` / `didDeactivate:`.
    // Tunnel never routes audio through the CallKit session.
}
