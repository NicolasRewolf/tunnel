import Foundation
import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class AppState {
    enum Screen {
        case home
        case onboarding
        case inCall
        case settings
    }

    static let shared = AppState()

    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "AppState")

    var screen: Screen = .home {
        didSet { recomputeKeepAwake() }
    }

    var config: FakeCallConfig {
        didSet { persistConfig() }
    }

    /// Last user-facing error from a trigger attempt (e.g. CallKit refused the
    /// call, daemon unavailable). Cleared by the view after it's been shown,
    /// or at the start of a new trigger.
    var lastTriggerError: String?

    // MARK: - Armed timer

    /// Absolute wall-clock instant at which an armed timer will fire.
    /// `nil` means no timer is currently armed.
    ///
    /// **Known limit:** if iOS suspends or terminates the app before the
    /// deadline, the firing is lost. Keeping the screen awake via
    /// `recomputeKeepAwake()` mitigates suspension as long as the user does
    /// not swipe the app away or lock the device manually.
    private(set) var armedDeadline: Date?

    /// Original duration the timer was armed with, in seconds. Used by the
    /// UI to draw a progression ring; stored alongside `armedDeadline` so
    /// the view layer doesn't need to track the start date itself.
    private(set) var armedTotalDuration: TimeInterval = 0

    private var armedTimerTask: Task<Void, Never>?

    private init() {
        config = Self.loadConfig()
    }

    // MARK: - Call lifecycle (CallKit-backed)

    /// Called by HomeView's "Sortir du tunnel" button (or by the armed timer
    /// when its deadline is reached). Delegates to CallKit so the incoming
    /// UI is consistent with the Back Tap / Action Button / Shortcut paths.
    func triggerFakeCallNow() {
        lastTriggerError = nil
        Task { [logger, config, weak self] in
            do {
                try await CallKitManager.shared.reportIncomingCall(
                    contactName: config.contactName
                )
            } catch {
                logger.error(
                    "triggerFakeCallNow failed: \(error.localizedDescription, privacy: .public) (\(String(describing: error), privacy: .public))"
                )
                self?.lastTriggerError = CallKitManager.userFacingMessage(for: error)
            }
        }
    }

    /// Called by InCallView's "Raccrocher" button.
    /// Asks CallKit to end the call; `didEndCallKit()` will flip the screen
    /// once `CXEndCallAction` is fulfilled by the delegate.
    func endCall() {
        CallKitManager.shared.endActiveCall()
    }

    // MARK: - CallKit callbacks

    /// Invoked by `CallKitManager` after the user accepts the incoming call.
    func didAnswerCallKit() {
        screen = .inCall  // didSet → recomputeKeepAwake
    }

    /// Invoked by `CallKitManager` after the user declines or hangs up,
    /// or after `providerDidReset`.
    func didEndCallKit() {
        if screen == .inCall { screen = .home }
        recomputeKeepAwake()  // defensive: idempotent
    }

    // MARK: - Armed timer API

    /// Schedules a fake call `duration` seconds from now. If a timer is
    /// already armed, it is replaced. Keeps the screen awake for the whole
    /// window to keep the app in foreground (our only insurance against
    /// iOS suspending us before the deadline).
    func armTimer(duration: TimeInterval) {
        disarmTimer()
        let deadline = Date.now.addingTimeInterval(duration)
        armedTotalDuration = duration
        armedDeadline = deadline
        recomputeKeepAwake()

        armedTimerTask = Task { @MainActor [weak self] in
            let remaining = deadline.timeIntervalSinceNow
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }
            guard let self, !Task.isCancelled else { return }
            // Clear state first so the UI transitions back to idle *before*
            // CallKit takes over the incoming-call UI.
            self.armedDeadline = nil
            self.armedTotalDuration = 0
            self.recomputeKeepAwake()
            self.triggerFakeCallNow()
        }
    }

    /// Cancels the armed timer, if any. No-op otherwise.
    func disarmTimer() {
        armedTimerTask?.cancel()
        armedTimerTask = nil
        armedDeadline = nil
        armedTotalDuration = 0
        recomputeKeepAwake()
    }

    // MARK: - Navigation

    func goHome() {
        screen = .home
    }

    func openSettings() {
        screen = .settings
    }

    func openOnboarding() {
        screen = .onboarding
    }

    // MARK: - Private

    /// Single source of truth for `isIdleTimerDisabled`. Called whenever any
    /// input into that decision (screen, armed timer) changes. Idempotent.
    private func recomputeKeepAwake() {
        let shouldKeep = armedDeadline != nil || screen == .inCall
        UIApplication.shared.isIdleTimerDisabled = shouldKeep
    }

    // MARK: - Persistence

    private func persistConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.config)
    }

    private static func loadConfig() -> FakeCallConfig {
        guard
            let data = UserDefaults.standard.data(forKey: StorageKeys.config),
            let config = try? JSONDecoder().decode(FakeCallConfig.self, from: data)
        else {
            return FakeCallConfig()
        }
        return config
    }
}

private enum StorageKeys {
    static let config = "app.config"
}
