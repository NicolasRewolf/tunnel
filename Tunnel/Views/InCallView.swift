import SwiftUI

/// iOS 26 Liquid Glass in-call screen.
/// Uses GlassEffectContainer for the 2x3 controls grid + tinted glass End button.
struct InCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 72
        static let topPadding: CGFloat = 64
        static let bottomPadding: CGFloat = 48
        static let endButtonSize: CGFloat = 74
        static let gridSpacing: CGFloat = 28
    }

    let appState: AppState
    @State private var callStartDate = Date()
    @Namespace private var glassNamespace

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: Layout.topPadding)

                contactAvatar
                    .padding(.bottom, 14)

                Text(appState.config.contactName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 1)

                TimelineView(.periodic(from: callStartDate, by: 1)) { timeline in
                    Text(durationLabel(for: timeline.date))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                }
                .padding(.top, 4)

                Spacer()

                controlsGrid
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)

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
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Controls grid (Liquid Glass)

    private var controlsGrid: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: Layout.gridSpacing) {
                HStack(spacing: Layout.gridSpacing) {
                    controlButton(icon: "mic.slash.fill", label: "Silence", id: "mute")
                    controlButton(icon: "square.grid.3x3.fill", label: "Clavier", id: "keypad")
                    controlButton(icon: "speaker.wave.2.fill", label: "Haut-parleur", id: "speaker")
                }
                HStack(spacing: Layout.gridSpacing) {
                    controlButton(icon: "plus", label: "Ajouter", id: "add")
                    controlButton(icon: "video.fill", label: "FaceTime", id: "facetime")
                    controlButton(icon: "person.crop.circle.fill", label: "Contacts", id: "contacts")
                }
            }
        }
    }

    private func controlButton(icon: String, label: String, id: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .glassEffect(.regular.interactive(), in: .circle)
                .glassEffectID(id, in: glassNamespace)

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.88))
                .frame(minWidth: 80)
        }
        .accessibilityHidden(true)
    }

    // MARK: - End button (tinted Liquid Glass)

    private var endCallButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            appState.endCall()
        }) {
            Image(systemName: "phone.down.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Layout.endButtonSize, height: Layout.endButtonSize)
                .glassEffect(
                    .regular.tint(Color(red: 0.97, green: 0.26, blue: 0.28)).interactive(),
                    in: .circle
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Raccrocher")
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
