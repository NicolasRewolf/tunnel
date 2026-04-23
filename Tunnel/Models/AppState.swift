import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AppState {
    enum Screen {
        case home
        case onboarding
        case incomingCall
        case inCall
        case settings
    }

    static let shared = AppState()

    var screen: Screen = .home
    var config: FakeCallConfig {
        didSet { persistConfig() }
    }

    private let ringtonePlayer = RingtonePlayer()
    private let hapticsManager = HapticsManager()
    private var isIncomingFeedbackActive = false

    private init() {
        config = Self.loadConfig()
    }

    // MARK: - Call lifecycle

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

    // MARK: - Navigation

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

    // MARK: - Feedback (audio + haptics)

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
