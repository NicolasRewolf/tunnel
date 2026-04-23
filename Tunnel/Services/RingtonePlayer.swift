import AVFoundation
import AudioToolbox
import OSLog

/// Plays a bundled ringtone on a loop.
/// Falls back to a repeated system alert sound if the bundled file can't be loaded.
@MainActor
final class RingtonePlayer: NSObject {
    private enum FallbackConstants {
        static let systemSoundID: SystemSoundID = 1003
        static let repeatInterval: TimeInterval = 2.2
    }

    private enum SupportedExtensions {
        static let all = ["caf", "m4a", "wav", "mp3"]
    }

    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "RingtonePlayer")
    private var player: AVAudioPlayer?
    private var fallbackTimer: Timer?

    override init() {
        super.init()
        registerInterruptionObserver()
    }

    func play(ringtoneName: String) {
        stop()

        guard let url = ringtoneURL(for: ringtoneName) else {
            logger.error("Missing bundled ringtone file: \(ringtoneName, privacy: .public)")
            playFallbackSystemRingtone()
            return
        }

        do {
            try activateAudioSession()
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            player?.play()
        } catch {
            logger.error("Failed to play ringtone: \(error.localizedDescription, privacy: .public)")
            playFallbackSystemRingtone()
        }
    }

    func stop() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil

        player?.stop()
        player = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private

    private func ringtoneURL(for ringtoneName: String) -> URL? {
        for fileExtension in SupportedExtensions.all {
            if let url = Bundle.main.url(forResource: ringtoneName, withExtension: fileExtension) {
                return url
            }
        }
        return nil
    }

    private func activateAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    private func playFallbackSystemRingtone() {
        AudioServicesPlaySystemSound(FallbackConstants.systemSoundID)
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: FallbackConstants.repeatInterval, repeats: true) { _ in
            Task { @MainActor in
                AudioServicesPlaySystemSound(FallbackConstants.systemSoundID)
            }
        }
        fallbackTimer?.tolerance = 0.15
    }

    /// Resumes the ringtone after a system interruption ends with `.shouldResume`.
    private func registerInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else {
            return
        }

        switch type {
        case .began:
            logger.info("Audio session interrupted; pausing ringtone.")
        case .ended:
            guard let optionsRaw = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
            if options.contains(.shouldResume), let player {
                do {
                    try activateAudioSession()
                    player.play()
                } catch {
                    logger.error("Failed to resume ringtone: \(error.localizedDescription, privacy: .public)")
                }
            }
        @unknown default:
            break
        }
    }
}
