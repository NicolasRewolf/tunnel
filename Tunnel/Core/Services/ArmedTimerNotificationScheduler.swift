import Foundation
import UserNotifications

/// Local notification fired at the armed-timer deadline so a kill / lock does not
/// silently drop the faux appel (user taps to run the same CallKit path as in-app).
enum ArmedTimerNotificationScheduler {
    static let requestIdentifier = "tunnel.armedTimer"

    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    static func schedule(at deadline: Date) async {
        cancel()
        let interval = deadline.timeIntervalSinceNow
        guard interval > 0.5 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Untunnel"
        content.body = "Touche pour lancer le faux appel."
        content.sound = .default

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
