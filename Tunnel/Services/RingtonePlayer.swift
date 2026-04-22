import AVFoundation
import AudioToolbox
import OSLog

@MainActor
final class RingtonePlayer: NSObject {
    private enum FallbackConstants {
        static let systemSoundID: SystemSoundID = 1003
        static let repeatInterval: TimeInterval = 2.2
    }
    private enum SupportedExtensions {
        static let all = ["caf", "m4a", "wav", "mp3"]
    }
    private enum SystemRingtone {
        static let defaultName = "default_ringtone"
        static let candidatePaths = [
            "/System/Library/Audio/UISounds/Ringtones/Reflection.m4r",
            "/System/Library/Audio/UISounds/Ringtones/Opening.m4r",
            "/System/Library/Audio/UISounds/Ringtones/Sencha.m4r",
            "/System/Library/Audio/UISounds/Ringtones/Default.m4r"
        ]
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

        guard let url = preferredRingtoneURL(for: ringtoneName) else {
            logger.error("Unable to find ringtone file: \(ringtoneName, privacy: .public) with supported extensions.")
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

    private func preferredRingtoneURL(for ringtoneName: String) -> URL? {
        if ringtoneName == SystemRingtone.defaultName,
           let systemDefaultURL = systemDefaultRingtoneURL() {
            return systemDefaultURL
        }

        return ringtoneURL(for: ringtoneName)
    }

    private func systemDefaultRingtoneURL() -> URL? {
        let fileManager = FileManager.default
        for path in SystemRingtone.candidatePaths where fileManager.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
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

    private func ringtoneURL(for ringtoneName: String) -> URL? {
        for fileExtension in SupportedExtensions.all {
            if let url = Bundle.main.url(forResource: ringtoneName, withExtension: fileExtension) {
                return url
            }
        }

        return nil
    }

    /// Resumes the ringtone after a system interruption (incoming notification, real call, etc.)
    /// when the system tells us the interruption ended with `.shouldResume`.
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
        handleInterruption(notification)
    }

    private func handleInterruption(_ notification: Notification) {
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
                    logger.error("Failed to resume ringtone after interruption: \(error.localizedDescription, privacy: .public)")
                }
            }
        @unknown default:
            break
        }
    }
}
