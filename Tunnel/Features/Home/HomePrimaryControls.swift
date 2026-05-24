import SwiftUI

struct HomePrimaryControls: View {
    let armedDeadline: Date?
    let onShowTimerPicker: () -> Void
    let onTriggerCall: () -> Void
    let onCancelTimer: () -> Void

    var body: some View {
        Group {
            if let deadline = armedDeadline {
                HomeArmedCTA(deadline: deadline, onCancel: onCancelTimer)
            } else {
                HomeIdleControls(
                    onShowTimerPicker: onShowTimerPicker,
                    onTriggerCall: onTriggerCall
                )
            }
        }
    }
}

private struct HomeIdleControls: View {
    let onShowTimerPicker: () -> Void
    let onTriggerCall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onShowTimerPicker) {
                Image(systemName: "timer")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())
            .accessibilityLabel("Programmer un faux appel plus tard")

            Button(action: onTriggerCall) {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Sortir du tunnel")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(Theme.green)
            .accessibilityLabel("Sortir du tunnel, déclenche un faux appel")
        }
    }
}

private struct HomeArmedCTA: View {
    let deadline: Date
    let onCancel: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Button(action: onCancel) {
                HStack(spacing: 10) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Annuler · \(HomeCountdown.string(until: deadline, at: context.date))")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(Theme.red)
            .accessibilityLabel("Annuler le minuteur")
            .accessibilityValue("Sortie du tunnel dans \(HomeCountdown.string(until: deadline, at: context.date))")
        }
    }
}
