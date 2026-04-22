import SwiftUI

/// Pixel-perfect iOS 17 in-call screen.
/// Matches Apple's native in-call UI with the 2x3 controls grid and red End button.
struct InCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 70
        static let topPadding: CGFloat = 64
        static let bottomPadding: CGFloat = 48
        static let endButtonSize: CGFloat = 72
        static let gridSpacing: CGFloat = 24
    }

    let appState: AppState
    @State private var callStartDate = Date()

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: Layout.topPadding)

                // Top identity block (compact, like iOS in-call)
                contactAvatar
                    .padding(.bottom, 12)

                Text(appState.config.contactName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 24)

                TimelineView(.periodic(from: callStartDate, by: 1)) { timeline in
                    Text(durationLabel(for: timeline.date))
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(.white.opacity(0.65))
                        .monospacedDigit()
                }
                .padding(.top, 3)

                Spacer()

                // 2x3 Controls grid (iOS native layout)
                controlsGrid
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                // End button
                endCallButton
                    .padding(.bottom, Layout.bottomPadding)
            }
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            callStartDate = Date()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.08),
                Color(red: 0.07, green: 0.08, blue: 0.12),
                Color(red: 0.02, green: 0.03, blue: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
        } else {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                }
        }
    }

    // MARK: - Controls grid

    private var controlsGrid: some View {
        VStack(spacing: Layout.gridSpacing) {
            HStack(spacing: Layout.gridSpacing) {
                inCallControl(icon: "mic.slash.fill", label: "Silence")
                inCallControl(icon: "square.grid.3x3.fill", label: "Clavier")
                inCallControl(icon: "speaker.wave.2.fill", label: "Haut-parleur")
            }
            HStack(spacing: Layout.gridSpacing) {
                inCallControl(icon: "plus", label: "Ajouter")
                inCallControl(icon: "video.fill", label: "FaceTime")
                inCallControl(icon: "person.crop.circle.fill", label: "Contacts")
            }
        }
    }

    private func inCallControl(icon: String, label: String) -> some View {
        // Decorative, non-interactive controls matching iOS in-call UI for realism.
        VStack(spacing: 8) {
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 68, height: 68)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white.opacity(0.92))
                }

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .frame(minWidth: 80)
        }
        .accessibilityHidden(true)
    }

    // MARK: - End button

    private var endCallButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            appState.endCall()
        }) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.28, blue: 0.30), Color(red: 0.86, green: 0.16, blue: 0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: Layout.endButtonSize, height: Layout.endButtonSize)
                .overlay {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Raccrocher")
    }

    // MARK: - Helpers

    private func durationLabel(for date: Date) -> String {
        let interval = max(0, date.timeIntervalSince(callStartDate))
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

#Preview {
    InCallView(appState: AppState.shared)
}
