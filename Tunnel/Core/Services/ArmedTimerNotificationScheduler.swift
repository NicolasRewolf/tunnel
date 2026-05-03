import Foundation
import UserNotifications

/// Local notification fired at the armed-timer deadline.
///
/// In normal operation the in-process `Task` (kept alive by
/// `BackgroundKeepAlive`) calls `reportNewIncomingCall` itself and CallKit
/// rings the device — this notification is then cancelled before delivery.
/// It only surfaces as a fallback when the audio keep-alive could not start
/// (e.g. arming during an active phone call) or the user force-quit the app.
///
/// Marked `.timeSensitive` so it pierces Focus modes the user may have set
/// (Sleep, Work, etc.) — without this it would be silently held until next
/// notification summary.
enum ArmedTimerNotificationScheduler {
    static let requestIdentifier = "tunnel.armedTimer"

    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .timeSensitive])
    }

    static func schedule(at deadline: Date) async {
        cancel()
        let interval = deadline.timeIntervalSinceNow
        guard interval > 0.5 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Untunnel"
        content.body = "Touche pour lancer le faux appel."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Synchronous: safe to call from `@MainActor` (e.g. disarm or after in-app fire).
    static func cancel() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [requestIdentifier])
    }
}
