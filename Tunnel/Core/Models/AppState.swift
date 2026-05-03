import Foundation
import Observation
import OSLog
import SwiftUI
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

    var profilesState: ProfilesState {
        didSet { persistProfilesState() }
    }

    /// Convenience access for view layers that only care about the active profile.
    /// Setting writes back into `profilesState` (and persists).
    var activeProfile: CallProfile {
        get {
            profilesState.activeProfile ?? profilesState.profiles.first ?? CallProfile()
        }
        set {
            var next = profilesState
            next.upsertProfile(newValue)
            next.setActiveProfile(id: newValue.id)
            profilesState = next
        }
    }

    // MARK: - Profiles API (UI helpers)

    func setActiveProfile(id: UUID) {
        var next = profilesState
        next.setActiveProfile(id: id)
        profilesState = next
    }

    func addProfile(_ profile: CallProfile) {
        var next = profilesState
        next.upsertProfile(profile)
        profilesState = next
    }

    func duplicateProfile(id: UUID) {
        guard let existing = profilesState.profiles.first(where: { $0.id == id }) else { return }
        var copy = existing
        copy.id = UUID()
        var next = profilesState
        next.profiles.append(copy)
        profilesState = next
    }

    func deleteProfiles(at offsets: IndexSet) {
        var next = profilesState
        next.profiles.remove(atOffsets: offsets)

        if next.profiles.isEmpty {
            let fallback = CallProfile()
            next = ProfilesState(single: fallback)
        } else if !next.profiles.contains(where: { $0.id == next.activeProfileID }) {
            next.activeProfileID = next.profiles[0].id
        }

        profilesState = next
    }

    func deleteProfile(id: UUID) {
        guard let idx = profilesState.profiles.firstIndex(where: { $0.id == id }) else { return }
        deleteProfiles(at: IndexSet(integer: idx))
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
        profilesState = Self.loadOrMigrateProfilesState()
        restoreArmedTimerFromStorageIfNeeded()
        restorePendingTriggerErrorFromStorage()
    }

    // MARK: - Call lifecycle (CallKit-backed)

    /// Called by HomeView's "Sortir du tunnel" button (or by the armed timer
    /// when its deadline is reached). Delegates to CallKit so the incoming
    /// UI is consistent with the Back Tap / Action Button / Shortcut paths.
    func triggerFakeCallNow() {
        acknowledgeTriggerError()
        Task { [logger, weak self] in
            do {
                let contactName = await MainActor.run { AppState.shared.activeProfile.contactName }
                try await CallKitManager.shared.reportIncomingCall(
                    contactName: contactName
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
        Self.persistArmedTimer(deadline: deadline, totalDuration: duration)
        BackgroundKeepAlive.shared.start()
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
        BackgroundKeepAlive.shared.stop()
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
        BackgroundKeepAlive.shared.start()
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
        // Release our audio session before CallKit takes over its own.
        BackgroundKeepAlive.shared.stop()
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

    private func persistProfilesState() {
        guard let data = try? JSONEncoder().encode(profilesState) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.callProfiles)
    }

    private static func loadLegacyConfig() -> FakeCallConfig? {
        guard
            let data = UserDefaults.standard.data(forKey: StorageKeys.config),
            let config = try? JSONDecoder().decode(FakeCallConfig.self, from: data)
        else {
            return nil
        }
        return config
    }

    private static func loadOrMigrateProfilesState() -> ProfilesState {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.callProfiles),
           let state = try? JSONDecoder().decode(ProfilesState.self, from: data),
           !state.profiles.isEmpty {
            return state
        }

        if let legacy = loadLegacyConfig() {
            // Migration: older versions stored a single `FakeCallConfig` at `app.config`.
            var initial = CallProfile()
            initial.contactName = legacy.contactName
            initial.contactSubtitle = legacy.contactSubtitle
            initial.contactImageData = legacy.contactImageData

            let migrated = ProfilesState(single: initial)
            if let data = try? JSONEncoder().encode(migrated) {
                UserDefaults.standard.set(data, forKey: StorageKeys.callProfiles)
            }
            return migrated
        }

        // Fresh install: bootstrap a few starter profiles.
        let starters: [CallProfile] = [
            seededProfile(
                name: "Crèche",
                subtitle: "Portable",
                symbol: "building.2.fill",
                colors: (UIColor.systemTeal, UIColor.systemBlue)
            ),
            seededProfile(
                name: "Ehpad",
                subtitle: "Portable",
                symbol: "cross.case.fill",
                colors: (UIColor.systemPink, UIColor.systemRed)
            ),
            seededProfile(
                name: "Astreinte",
                subtitle: "Portable",
                symbol: "person.badge.clock.fill",
                colors: (UIColor.systemIndigo, UIColor.systemPurple)
            ),
        ]

        let seeded = ProfilesState(profiles: starters, activeProfileID: starters[0].id)
        if let data = try? JSONEncoder().encode(seeded) {
            UserDefaults.standard.set(data, forKey: StorageKeys.callProfiles)
        }
        return seeded
    }

    private static func seededProfile(
        name: String,
        subtitle: String,
        symbol: String,
        colors: (UIColor, UIColor)
    ) -> CallProfile {
        var p = CallProfile()
        p.contactName = name
        p.contactSubtitle = subtitle
        p.contactImageData = seededAvatarJPEGData(symbol: symbol, colors: colors)
        return p
    }

    private static func seededAvatarJPEGData(
        symbol: String,
        colors: (UIColor, UIColor)
    ) -> Data? {
        let size = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            // Background gradient
            let cgColors = [colors.0.cgColor, colors.1.cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            } else {
                colors.0.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }

            // Subtle vignette
            UIColor.black.withAlphaComponent(0.12).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: -120, y: -80, width: 520, height: 520))
            UIColor.black.withAlphaComponent(0.18).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 220, y: 260, width: 560, height: 560))

            // Symbol
            let pointSize: CGFloat = 250
            let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            let symbolImage = UIImage(systemName: symbol, withConfiguration: config)
            let tint = UIColor.white.withAlphaComponent(0.95)
            let rendered = symbolImage?.withTintColor(tint, renderingMode: .alwaysOriginal)

            if let rendered {
                let rect = CGRect(
                    x: (size.width - pointSize) / 2,
                    y: (size.height - pointSize) / 2,
                    width: pointSize,
                    height: pointSize
                )
                rendered.draw(in: rect)
            }
        }
        return image.jpegData(compressionQuality: 0.90)
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
    static let callProfiles = "app.callProfiles"
    static let armedDeadline = "app.armedDeadline"
    static let armedTotalDuration = "app.armedTotalDuration"
    static let pendingIntentTriggerError = "app.pendingIntentTriggerError"
}
