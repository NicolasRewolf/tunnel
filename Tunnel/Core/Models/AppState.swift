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
    private let profilesStore = ProfilesStore()

    var screen: Screen = .home {
        didSet { recomputeKeepAwake() }
    }

    var profilesState: ProfilesState {
        didSet { profilesStore.save(profilesState) }
    }

    /// Convenience access for view layers that only care about the active profile.
    /// Setting writes back into `profilesState` (and persists).
    var activeProfile: CallProfile {
        get {
            if let profile = profilesState.activeProfile {
                return profile
            }
            if let first = profilesState.profiles.first {
                logger.warning("activeProfileID invalid — using first profile")
                return first
            }
            return CallProfile()
        }
        set {
            updateProfiles { state in
                state.upsertProfile(newValue)
                state.setActiveProfile(id: newValue.id)
            }
        }
    }

    // MARK: - Profiles API (UI helpers)

    func setActiveProfile(id: UUID) {
        updateProfiles { $0.setActiveProfile(id: id) }
    }

    func upsertProfile(_ profile: CallProfile) {
        updateProfiles { $0.upsertProfile(profile) }
    }

    func duplicateProfile(id: UUID) {
        guard let existing = profilesState.profiles.first(where: { $0.id == id }) else { return }
        var copy = existing
        copy.id = UUID()
        updateProfiles { $0.profiles.append(copy) }
    }

    func deleteProfile(id: UUID) {
        updateProfiles { $0.deleteProfile(id: id) }
    }

    func deleteProfiles(at offsets: IndexSet) {
        updateProfiles { $0.deleteProfiles(at: offsets) }
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

    /// `true` if this launch started with data persisted by a prior version
    /// (legacy `app.config` or `app.callProfiles`). Snapshotted at init,
    /// before migration writes anything, so it remains accurate for the
    /// lifetime of the process. Used by the one-shot upgrade announcement
    /// to distinguish "user upgrading" from "first install".
    let launchedFromPriorVersion: Bool

    /// Reactive mode: keep the audio session active 24/7 so ad-hoc
    /// triggers (Action Button, Back Tap) fire instantly even when the
    /// iPhone has been face-down + locked + idle for a long time. Costs
    /// battery (~5-10%/day). Off by default.
    var isReactiveModeEnabled: Bool {
        didSet {
            guard oldValue != isReactiveModeEnabled else { return }
            UserDefaults.standard.set(isReactiveModeEnabled, forKey: StorageKeys.reactiveModeEnabled)
            applyReactiveModeDemand()
        }
    }

    private init() {
        launchedFromPriorVersion = profilesStore.hadPriorVersionData()

        isReactiveModeEnabled = UserDefaults.standard.bool(forKey: StorageKeys.reactiveModeEnabled)

        profilesState = profilesStore.loadOrMigrate()
        restoreArmedTimerFromStorageIfNeeded()
        restorePendingTriggerErrorFromStorage()

        // Brand-new install: silently mark the upgrade announcement as seen
        // so we never bother users who never saw the prior onboarding copy.
        if !launchedFromPriorVersion {
            UserDefaults.standard.set(true, forKey: StorageKeys.seenShortcutAnnouncementV1)
        }

        // Honor the persisted reactive-mode flag from the very first
        // launch tick: if the user enabled it, the keep-alive must be
        // running before the app even reaches HomeView.
        applyReactiveModeDemand()
    }

    private func applyReactiveModeDemand() {
        if isReactiveModeEnabled {
            BackgroundKeepAlive.shared.request(for: .reactiveMode)
        } else {
            BackgroundKeepAlive.shared.release(for: .reactiveMode)
        }
    }

    // MARK: - One-shot announcement (post-update discoverability)

    /// `true` once on first launch after updating from a prior version, so
    /// existing users get the same fallback path that new onboarders see in
    /// the Toucher au dos card. Idempotent: flips to `false` permanently
    /// once `markShortcutAnnouncementSeen()` is called.
    var shouldOfferShortcutAnnouncement: Bool {
        launchedFromPriorVersion
            && !UserDefaults.standard.bool(forKey: StorageKeys.seenShortcutAnnouncementV1)
    }

    func markShortcutAnnouncementSeen() {
        UserDefaults.standard.set(true, forKey: StorageKeys.seenShortcutAnnouncementV1)
    }

    // MARK: - Call lifecycle (CallKit-backed)

    /// Called by HomeView's "Sortir du tunnel" button (or by the armed timer
    /// when its deadline is reached). Delegates to CallKit so the incoming
    /// UI is consistent with the Back Tap / Action Button / Shortcut paths.
    func triggerFakeCallNow() {
        acknowledgeTriggerError()
        let contactName = activeProfile.contactName
        Task { [logger, weak self, contactName] in
            do {
                try await CallKitManager.shared.reportIncomingCall(contactName: contactName)
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
    ///
    /// Starts a silent-audio keep-alive so the in-process Task fires even
    /// when the iPhone is locked, screen-down, or has been idle in a pocket.
    /// The local notification stays scheduled as a fallback (force-quit, audio
    /// session refused).
    func armTimer(duration: TimeInterval) {
        disarmTimer()
        let deadline = Date.now.addingTimeInterval(duration)
        armedTotalDuration = duration
        armedDeadline = deadline
        ArmedTimerPersistence.persist(deadline: deadline, totalDuration: duration)
        BackgroundKeepAlive.shared.request(for: .armedTimer)
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
        ArmedTimerPersistence.clear()
        armedDeadline = nil
        armedTotalDuration = 0
        BackgroundKeepAlive.shared.release(for: .armedTimer)
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
        guard let snapshot = ArmedTimerPersistence.load() else { return }

        armedTotalDuration = snapshot.totalDuration
        armedDeadline = snapshot.deadline
        BackgroundKeepAlive.shared.request(for: .armedTimer)
        recomputeKeepAwake()
        startArmedTimerTask(until: snapshot.deadline)
        Task {
            await ArmedTimerNotificationScheduler.requestAuthorizationIfNeeded()
            await ArmedTimerNotificationScheduler.schedule(at: snapshot.deadline)
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
        ArmedTimerPersistence.clear()
        armedDeadline = nil
        armedTotalDuration = 0
        // Release our audio session before CallKit takes over its own.
        BackgroundKeepAlive.shared.release(for: .armedTimer)
        recomputeKeepAwake()
        triggerFakeCallNow()
    }

    // MARK: - Private

    private func updateProfiles(_ transform: (inout ProfilesState) -> Void) {
        var next = profilesState
        transform(&next)
        profilesState = next
    }

    /// Single source of truth for `isIdleTimerDisabled`. Called whenever any
    /// input into that decision (screen, armed timer) changes. Idempotent.
    private func recomputeKeepAwake() {
        let shouldKeep = armedDeadline != nil || screen == .inCall
        UIApplication.shared.isIdleTimerDisabled = shouldKeep
    }
}

private enum StorageKeys {
    static let armedDeadline = "app.armedDeadline"
    static let armedTotalDuration = "app.armedTotalDuration"
    static let pendingIntentTriggerError = "app.pendingIntentTriggerError"
    /// Bumped to v2/v3/... whenever a new post-update announcement is added.
    static let seenShortcutAnnouncementV1 = "app.seenShortcutAnnouncement.v1"
    static let reactiveModeEnabled = "app.reactiveModeEnabled"
}
