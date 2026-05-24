import SwiftUI

struct HomeSubtitle: View {
    let armedDeadline: Date?

    var body: some View {
        Group {
            if let deadline = armedDeadline {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text("Sortie du tunnel dans \(HomeCountdown.string(until: deadline, at: context.date))")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(Theme.green)
                        .contentTransition(.numericText(countsDown: true))
                }
            } else {
                Text("Sortir d'une conversation en un geste.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}
