import SwiftUI

struct InCallView: View {
    let appState: AppState
    @State private var callStartDate = Date()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Text("En appel")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.65))

                Text(appState.config.contactName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                TimelineView(.periodic(from: callStartDate, by: 1)) { timeline in
                    Text(durationLabel(for: timeline.date))
                        .font(.system(size: 42, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                CallActionButton(
                    systemImage: "phone.down.fill",
                    backgroundColor: .red,
                    accessibilityLabel: "Raccrocher",
                    title: "Raccrocher"
                ) {
                    appState.endCall()
                }
                .padding(.bottom, 56)
            }
            .padding(.top, 90)
        }
        .statusBarHidden(true)
        .onAppear {
            callStartDate = Date()
        }
    }

    private func durationLabel(for date: Date) -> String {
        let interval = date.timeIntervalSince(callStartDate)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    InCallView(appState: AppState.shared)
}
