import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AppState {
    enum Screen {
        case onboarding
        case home
        case incomingCall
        case inCall
        case settings
    }

    static let shared = AppState()

    var screen: Screen = .home
    var config: FakeCallConfig {
        didSet {
            persistConfig()
        }
    }

    private let ringtonePlayer = RingtonePlayer()
    private let hapticsManager = HapticsManager()
    private var hasSeenOnboarding: Bool
    private var isIncomingFeedbackActive = false

    private init() {
        config = Self.loadConfig()
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: StorageKeys.hasSeenOnboarding)
        screen = hasSeenOnboarding ? .home : .onboarding
    }

    func triggerFakeCallNow() {
        guard screen != .incomingCall else { return }
        setKeepScreenAwake(true)
        screen = .incomingCall
        startIncomingFeedback()
    }

    func answerCall() {
        guard screen == .incomingCall else { return }
        stopIncomingFeedback()
        screen = .inCall
    }

    func endCall() {
        stopIncomingFeedback()
        setKeepScreenAwake(false)
        screen = .home
    }

    func goHome() {
        stopIncomingFeedback()
        setKeepScreenAwake(false)
        screen = .home
    }

    func openSettings() {
        stopIncomingFeedback()
        setKeepScreenAwake(false)
        screen = .settings
    }

    func openOnboarding() {
        stopIncomingFeedback()
        setKeepScreenAwake(false)
        screen = .onboarding
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: StorageKeys.hasSeenOnboarding)
        screen = .home
    }

    func dismissOnboarding() {
        // Skip without marking as seen, so the user is reminded next launch.
        screen = .home
    }

    private func startIncomingFeedback() {
        guard !isIncomingFeedbackActive else { return }
        isIncomingFeedbackActive = true
        ringtonePlayer.play(ringtoneName: config.ringtoneName)
        hapticsManager.startIncomingCallPattern()
    }

    private func stopIncomingFeedback() {
        guard isIncomingFeedbackActive else { return }
        isIncomingFeedbackActive = false
        ringtonePlayer.stop()
        hapticsManager.stop()
    }

    private func setKeepScreenAwake(_ enabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = enabled
    }

    private func persistConfig() {
        let defaults = UserDefaults.standard
        defaults.set(config.contactName, forKey: StorageKeys.contactName)
        defaults.set(config.contactSubtitle, forKey: StorageKeys.contactSubtitle)
        defaults.set(config.fakePhoneNumber, forKey: StorageKeys.fakePhoneNumber)
        defaults.set(config.ringtoneName, forKey: StorageKeys.ringtoneName)
        defaults.set(config.useSlideToAnswer, forKey: StorageKeys.useSlideToAnswer)
        defaults.set(config.contactImageName, forKey: StorageKeys.contactImageName)
        if let data = config.contactImageData {
            defaults.set(data, forKey: StorageKeys.contactImageData)
        } else {
            defaults.removeObject(forKey: StorageKeys.contactImageData)
        }
    }

    private static func loadConfig() -> FakeCallConfig {
        let defaults = UserDefaults.standard

        return FakeCallConfig(
            contactName: defaults.string(forKey: StorageKeys.contactName) ?? FakeCallConfig.Defaults.contactName,
            contactSubtitle: defaults.string(forKey: StorageKeys.contactSubtitle) ?? FakeCallConfig.Defaults.contactSubtitle,
            fakePhoneNumber: defaults.string(forKey: StorageKeys.fakePhoneNumber) ?? FakeCallConfig.Defaults.fakePhoneNumber,
            ringtoneName: defaults.string(forKey: StorageKeys.ringtoneName) ?? FakeCallConfig.Defaults.ringtoneName,
            useSlideToAnswer: defaults.object(forKey: StorageKeys.useSlideToAnswer) as? Bool ?? FakeCallConfig.Defaults.useSlideToAnswer,
            contactImageName: defaults.string(forKey: StorageKeys.contactImageName),
            contactImageData: defaults.data(forKey: StorageKeys.contactImageData)
        )
    }
}

private enum StorageKeys {
    static let hasSeenOnboarding = "app.hasSeenOnboarding"
    static let contactName = "config.contactName"
    static let contactSubtitle = "config.contactSubtitle"
    static let fakePhoneNumber = "config.fakePhoneNumber"
    static let ringtoneName = "config.ringtoneName"
    static let useSlideToAnswer = "config.useSlideToAnswer"
    static let contactImageName = "config.contactImageName"
    static let contactImageData = "config.contactImageData"
}
