import CoreHaptics
import OSLog
import UIKit

@MainActor
final class HapticsManager {
    private enum PatternConstants {
        static let pulseInterval: TimeInterval = 0.2
        static let activeDuration: TimeInterval = 1.0
        static let fullCycleDuration: TimeInterval = 3.0
    }

    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "HapticsManager")
    private var engine: CHHapticEngine?
    private var cycleTimer: Timer?
    private var fallbackTimer: Timer?

    func startIncomingCallPattern() {
        stop()

        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            logger.info("Haptics unsupported on this device.")
            startFallbackPattern()
            return
        }

        do {
            let newEngine = try CHHapticEngine()
            configureHandlers(for: newEngine)
            try newEngine.start()
            engine = newEngine
            startEngineDrivenPattern()
        } catch {
            logger.error("Unable to start haptics engine: \(error.localizedDescription, privacy: .public)")
            startFallbackPattern()
        }
    }

    func stop() {
        cycleTimer?.invalidate()
        cycleTimer = nil

        fallbackTimer?.invalidate()
        fallbackTimer = nil

        engine?.stop(completionHandler: nil)
        engine = nil
    }

    private func configureHandlers(for engine: CHHapticEngine) {
        engine.stoppedHandler = { [weak self] reason in
            self?.logger.info("Haptic engine stopped: \(String(describing: reason), privacy: .public)")
        }

        engine.resetHandler = { [weak self] in
            guard let self else { return }
            do {
                try self.engine?.start()
            } catch {
                self.logger.error("Unable to restart haptics after reset: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func callPatternEvents() -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        var currentTime: TimeInterval = 0

        while currentTime < PatternConstants.activeDuration {
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        .init(parameterID: .hapticIntensity, value: 1.0),
                        .init(parameterID: .hapticSharpness, value: 0.9)
                    ],
                    relativeTime: currentTime
                )
            )
            currentTime += PatternConstants.pulseInterval
        }

        return events
    }

    private func startFallbackPattern() {
        let generator = UINotificationFeedbackGenerator()

        fallbackTimer = Timer.scheduledTimer(withTimeInterval: PatternConstants.fullCycleDuration, repeats: true) { _ in
            Task { @MainActor in
                generator.notificationOccurred(.warning)
            }
        }
        fallbackTimer?.tolerance = 0.2
        fallbackTimer?.fire()
    }

    private func startEngineDrivenPattern() {
        cycleTimer = Timer.scheduledTimer(withTimeInterval: PatternConstants.fullCycleDuration, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.playOneHapticBurst()
            }
        }
        cycleTimer?.tolerance = 0.1
        playOneHapticBurst()
    }

    private func playOneHapticBurst() {
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: callPatternEvents(), parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            logger.error("Unable to play haptic burst: \(error.localizedDescription, privacy: .public)")
        }
    }
}
