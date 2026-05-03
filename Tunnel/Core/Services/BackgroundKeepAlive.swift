import AVFoundation
import OSLog

/// Keeps the app process alive in the background while an armed timer is
/// running, so the trigger fires precisely at the deadline regardless of
/// whether the iPhone is locked, screen-down on a table, or has been idle for
/// a long time in a pocket.
///
/// Mechanism: declares the `audio` background mode in `Info.plist` and plays
/// an inaudible buffer through `AVAudioEngine` with `.mixWithOthers` so it
/// never interrupts whatever the user is listening to (music, podcast, call).
/// iOS keeps the process running as long as audio is playing.
///
/// Why this is necessary: there is no public-API way for a non-VoIP app to
/// schedule `CXProvider.reportNewIncomingCall` at a precise future instant.
/// The only options are (a) the user taps a local notification — fragile when
/// the phone is in a pocket — or (b) the app is alive at the deadline and
/// calls CallKit itself. This class enables (b).
///
/// Compliance:
///  - No audio is actually rendered (zero-filled PCM buffer).
///  - `.mixWithOthers` ensures no ducking or interruption of other sessions.
///  - Started **only** while a timer is armed; stopped immediately on
///    disarm, fire, or app reset. Battery footprint is bounded by the
///    armed window (typically 5–60 min).
///
/// The local notification fallback (`ArmedTimerNotificationScheduler`) is
/// kept as a belt-and-suspenders for the rare cases where the audio session
/// is refused (active phone call when arming, system audio policies) or the
/// app is force-quit by the user.
@MainActor
final class BackgroundKeepAlive {
    static let shared = BackgroundKeepAlive()

    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "BackgroundKeepAlive")

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var nodesAttached = false
    private(set) var isRunning = false

    private init() {}

    /// Starts the silent loop. No-op if already running.
    /// Failure (audio session refused, engine won't start) is logged and
    /// swallowed: the local-notification fallback still covers the deadline.
    func start() {
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true, options: [])
        } catch {
            logger.error(
                "Audio session activation failed: \(error.localizedDescription, privacy: .public)"
            )
            return
        }

        let format = engine.outputNode.inputFormat(forBus: 0)
        let frameCount = AVAudioFrameCount(max(1, format.sampleRate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            logger.error("Could not allocate silent buffer")
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            return
        }
        // PCM buffers are zero-filled at allocation; we just need a non-zero
        // frame length so the engine has something to render (silently).
        buffer.frameLength = frameCount

        if !nodesAttached {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            nodesAttached = true
        }

        do {
            try engine.start()
        } catch {
            logger.error(
                "Audio engine start failed: \(error.localizedDescription, privacy: .public)"
            )
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            return
        }

        player.scheduleBuffer(buffer, at: nil, options: [.loops])
        player.play()
        isRunning = true
        logger.info("Silent keep-alive started")
    }

    /// Stops the loop and releases the audio session for other apps.
    /// Safe to call repeatedly.
    func stop() {
        guard isRunning else { return }
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: [.notifyOthersOnDeactivation]
        )
        isRunning = false
        logger.info("Silent keep-alive stopped")
    }
}
