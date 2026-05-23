import Foundation

/// UserDefaults keys and helpers for the armed fake-call timer.
enum ArmedTimerPersistence {
    enum Key {
        static let deadline = "app.armedDeadline"
        static let totalDuration = "app.armedTotalDuration"
    }

    struct Snapshot {
        let deadline: Date
        let totalDuration: TimeInterval
    }

    static func load(from defaults: UserDefaults = .standard) -> Snapshot? {
        guard let ts = defaults.object(forKey: Key.deadline) as? TimeInterval else {
            return nil
        }
        let deadline = Date(timeIntervalSince1970: ts)
        guard deadline > Date.now else {
            clear(from: defaults)
            ArmedTimerNotificationScheduler.cancel()
            return nil
        }

        var total = defaults.double(forKey: Key.totalDuration)
        if total <= 0 {
            total = max(deadline.timeIntervalSinceNow, 60)
            persist(deadline: deadline, totalDuration: total, to: defaults)
        }
        return Snapshot(deadline: deadline, totalDuration: total)
    }

    static func persist(deadline: Date, totalDuration: TimeInterval, to defaults: UserDefaults = .standard) {
        defaults.set(deadline.timeIntervalSince1970, forKey: Key.deadline)
        defaults.set(totalDuration, forKey: Key.totalDuration)
    }

    static func clear(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: Key.deadline)
        defaults.removeObject(forKey: Key.totalDuration)
    }
}
