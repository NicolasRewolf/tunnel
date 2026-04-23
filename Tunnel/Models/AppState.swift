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

    var screen: Screen = .home
    var config: FakeCallConfig {
        didSet { persistConfig() }
    }

    /// Last user-facing error from a trigger attempt (e.g. CallKit refused the
    /// call, daemon unavailable). Cleared by the view after it's been shown,
    /// or at the start of a new trigger.
    var lastTriggerError: String?

    private init() {
        config = Self.loadConfig()
    }

    // MARK: - Call lifecycle (CallKit-backed)

    /// Called by HomeView's "Sortir du tunnel" button.
    /// Delegates to CallKit so the incoming-call UI is consistent with the
    /// Back Tap / Action Button / Shortcut paths.
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
        setKeepScreenAwake(true)
        screen = .inCall
    }

    /// Invoked by `CallKitManager` after the user declines or hangs up,
    /// or after `providerDidReset`.
    func didEndCallKit() {
        setKeepScreenAwake(false)
        if screen == .inCall { screen = .home }
    }

    // MARK: - Navigation

    func goHome() {
        setKeepScreenAwake(false)
        screen = .home
    }

    func openSettings() {
        setKeepScreenAwake(false)
        screen = .settings
    }

    func openOnboarding() {
        setKeepScreenAwake(false)
        screen = .onboarding
    }

    // MARK: - Private

    private func setKeepScreenAwake(_ enabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = enabled
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
