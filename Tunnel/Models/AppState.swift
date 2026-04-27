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
    /// Persistence + a local notification at `deadline` cover kill / lock: the
    /// user can tap the notification to run the same CallKit path. If the app
    /// stays alive, the in-process `Task` fires and cancels that notification.
    private(set) var armedDeadline: Date?

    /// Original duration the timer was armed with, in seconds. Used by the
    /// UI to draw a progression ring; stored alongside `armedDeadline` so
    /// the view layer doesn't need to track the start date itself.
    private(set) var armedTotalDuration: TimeInterval = 0

    private var armedTimerTask: Task<Void, Never>?

    private init() {
        config = Self.loadConfig()
        restoreArmedTimerFromStorageIfNeeded()
        restorePendingTriggerErrorFromStorage()
    }

    // MARK: - Call lifecycle (CallKit-backed)

    /// Called by HomeView's "Sortir du tunnel" button (or by the armed timer
    /// when its deadline is reached). Delegates to CallKit so the incoming
    /// UI is consistent with the Back Tap / Action Button / Shortcut paths.
    func triggerFakeCallNow() {
        acknowledgeTriggerError()
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
    /// already armed, it is replaced.
    func armTimer(duration: TimeInterval) {
        disarmTimer()
        let deadline = Date.now.addingTimeInterval(duration)
        armedTotalDuration = duration
        armedDeadline = deadline
        Self.persistArmedTimer(deadline: deadline, totalDuration: duration)
        recomputeKeepAwake()
        startArmedTimerTask(until: deadline)
        Task {
            await ArmedTimerNotificationScheduler.requestAuthorizationIfNeeded()
            await ArmedTimerNotificationScheduler.schedule(at: deadline)
        }
    }

    /// Cancels the armed timer, if any. No-op otherwise.
    func disarmTimer() {
        armedTimerTask?.cancel()
        armedTimerTask = nil
        ArmedTimerNotificationScheduler.cancel()
        Self.clearArmedTimerPersistence()
        armedDeadline = nil
        armedTotalDuration = 0
        recomputeKeepAwake()
    }

    /// User tapped the scheduled local notification (app may have been killed).
    func userTappedArmedTimerNotification() {
        disarmTimer()
        triggerFakeCallNow()
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

    // MARK: - Erreurs de déclenchement (raccourci = pas de toast si app inactive)

    /// Raccourci / Siri : mémorise l’échec pour l’afficher à la prochaine ouverture d’`HomeView`.
    func recordIntentTriggerFailure(_ message: String) {
        lastTriggerError = message
        UserDefaults.standard.set(message, forKey: StorageKeys.pendingIntentTriggerError)
    }

    /// Dismiss explicite du bandeau d’erreur (incl. stockage persistant).
    func acknowledgeTriggerError() {
        lastTriggerError = nil
        UserDefaults.standard.removeObject(forKey: StorageKeys.pendingIntentTriggerError)
    }

    private func restorePendingTriggerErrorFromStorage() {
        guard let s = UserDefaults.standard.string(forKey: StorageKeys.pendingIntentTriggerError),
              !s.isEmpty
        else { return }
        lastTriggerError = s
    }

    // MARK: - Armed timer internals

    private func restoreArmedTimerFromStorageIfNeeded() {
        guard let ts = UserDefaults.standard.object(forKey: StorageKeys.armedDeadline) as? TimeInterval else {
            return
        }
        let deadline = Date(timeIntervalSince1970: ts)
        guard deadline > Date.now else {
            Self.clearArmedTimerPersistence()
            ArmedTimerNotificationScheduler.cancel()
            return
        }

        var total = UserDefaults.standard.double(forKey: StorageKeys.armedTotalDuration)
        if total <= 0 {
            total = max(deadline.timeIntervalSinceNow, 60)
            Self.persistArmedTimer(deadline: deadline, totalDuration: total)
        }

        armedTotalDuration = total
        armedDeadline = deadline
        recomputeKeepAwake()
        startArmedTimerTask(until: deadline)
        Task {
            await ArmedTimerNotificationScheduler.requestAuthorizationIfNeeded()
            await ArmedTimerNotificationScheduler.schedule(at: deadline)
        }
    }

    private func startArmedTimerTask(until deadline: Date) {
        armedTimerTask?.cancel()
        armedTimerTask = Task { @MainActor [weak self] in
            let remaining = deadline.timeIntervalSinceNow
            if remaining > 0 {
                let ns = min(remaining * 1_000_000_000, Double(UInt64.max))
                let nanos = UInt64(max(0, ns))
                if nanos > 0 { try? await Task.sleep(nanoseconds: nanos) }
            }
            guard let self, !Task.isCancelled else { return }
            self.finishArmedTimerFromSleep()
        }
    }

    private func finishArmedTimerFromSleep() {
        armedTimerTask = nil
        ArmedTimerNotificationScheduler.cancel()
        Self.clearArmedTimerPersistence()
        armedDeadline = nil
        armedTotalDuration = 0
        recomputeKeepAwake()
        triggerFakeCallNow()
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

    private static func persistArmedTimer(deadline: Date, totalDuration: TimeInterval) {
        UserDefaults.standard.set(deadline.timeIntervalSince1970, forKey: StorageKeys.armedDeadline)
        UserDefaults.standard.set(totalDuration, forKey: StorageKeys.armedTotalDuration)
    }

    private static func clearArmedTimerPersistence() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.armedDeadline)
        UserDefaults.standard.removeObject(forKey: StorageKeys.armedTotalDuration)
    }
}

private enum StorageKeys {
    static let config = "app.config"
    static let armedDeadline = "app.armedDeadline"
    static let armedTotalDuration = "app.armedTotalDuration"
    static let pendingIntentTriggerError = "app.pendingIntentTriggerError"
}
