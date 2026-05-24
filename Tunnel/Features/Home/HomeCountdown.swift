import Foundation

enum HomeCountdown {
    /// Formats `mm:ss` remaining between `now` and `deadline`, clamped at 0.
    /// Rounds up so the first second shown matches the arming duration.
    static func string(until deadline: Date, at now: Date) -> String {
        let remaining = max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
