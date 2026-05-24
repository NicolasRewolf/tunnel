import SwiftUI

struct HomeHeroIcon: View {
    let isArmed: Bool
    let armedDeadline: Date?
    let armedTotalDuration: TimeInterval
    @Binding var pulseRing: Bool

    var body: some View {
        ZStack {
            if isArmed {
                HomeProgressionRing(deadline: armedDeadline, totalDuration: armedTotalDuration)
            } else {
                HomePulseRings(pulseRing: pulseRing)
            }

            Image(systemName: isArmed ? "timer" : "phone.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 130, height: 130)
                .glassEffect(.regular.tint(Theme.green), in: .circle)
                .shadow(color: Theme.greenDeep.opacity(0.5), radius: 22, x: 0, y: 10)
                .contentTransition(.symbolEffect(.replace))
        }
        .onAppear { pulseRing = true }
        .accessibilityHidden(true)
    }
}

private struct HomePulseRings: View {
    let pulseRing: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.green.opacity(0.25), lineWidth: 1)
                .frame(width: 170, height: 170)
                .scaleEffect(pulseRing ? 1.12 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false),
                    value: pulseRing
                )

            Circle()
                .stroke(Theme.green.opacity(0.35), lineWidth: 1)
                .frame(width: 150, height: 150)
                .scaleEffect(pulseRing ? 1.15 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(0.6),
                    value: pulseRing
                )
        }
    }
}

private struct HomeProgressionRing: View {
    let deadline: Date?
    let totalDuration: TimeInterval

    var body: some View {
        if let deadline, totalDuration > 0 {
            let total = totalDuration
            TimelineView(.animation(minimumInterval: 0.05, paused: false)) { context in
                let remaining = max(0, deadline.timeIntervalSince(context.date))
                let progress = max(0, min(1, 1 - (remaining / total)))
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.green,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 158, height: 158)
            }
        }
    }
}
