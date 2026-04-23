import SwiftUI

/// Minimalist in-call screen: avatar, name, timer, single End button.
struct InCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 92
        static let topPadding: CGFloat = 80
        static let bottomPadding: CGFloat = 56
        static let endButtonSize: CGFloat = 74
    }

    let appState: AppState
    @State private var callStartDate = Date()

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: Layout.topPadding)

                contactAvatar
                    .padding(.bottom, 20)

                Text(appState.config.contactName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 1)

                TimelineView(.periodic(from: callStartDate, by: 1)) { timeline in
                    Text(durationLabel(for: timeline.date))
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.72))
                        .monospacedDigit()
                }
                .padding(.top, 6)

                Spacer()

                endCallButton
                    .padding(.bottom, Layout.bottomPadding)
            }
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear { callStartDate = Date() }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.06, blue: 0.10),
                    Color(red: 0.02, green: 0.03, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.20, green: 0.26, blue: 0.40).opacity(0.25), .clear],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: 360
            )
            .ignoresSafeArea()
            .blendMode(.screen)
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var contactAvatar: some View {
        if let data = appState.config.contactImageData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        } else {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))
                    .glassEffect(.regular, in: .circle)
                    .frame(width: Layout.avatarSize, height: Layout.avatarSize)

                Image(systemName: "person.fill")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: - End button

    private var endCallButton: some View {
        Button(action: endCall) {
            Image(systemName: "phone.down.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Layout.endButtonSize, height: Layout.endButtonSize)
                .glassEffect(.regular.tint(Theme.red).interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Raccrocher")
    }

    // MARK: - Private

    private func endCall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        appState.endCall()
    }

    private func durationLabel(for date: Date) -> String {
        let interval = max(0, date.timeIntervalSince(callStartDate))
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    InCallView(appState: AppState.shared)
}
