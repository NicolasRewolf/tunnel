import SwiftUI

/// Minimalist in-call screen: avatar, name, timer, single End button.
struct InCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 92
        static let topPadding: CGFloat = 80
        static let bottomPadding: CGFloat = 56
        static let endButtonSize: CGFloat = 74
        static let controlsHorizontalPadding: CGFloat = 34
        static let controlsRowSpacing: CGFloat = 26
        static let controlsColumnSpacing: CGFloat = 22
    }

    let appState: AppState
    @State private var callStartDate = Date()
    @State private var isMuted = false
    @State private var isSpeakerOn = false

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

                controlsGrid
                    .padding(.horizontal, Layout.controlsHorizontalPadding)
                    .padding(.bottom, 44)

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

    // MARK: - Controls

    private var controlsGrid: some View {
        VStack(spacing: Layout.controlsRowSpacing) {
            HStack(spacing: Layout.controlsColumnSpacing) {
                InCallControlButton(
                    title: "Muet",
                    systemImage: isMuted ? "mic.slash.fill" : "mic.slash",
                    isActive: isMuted,
                    activeTint: .white
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isMuted.toggle()
                }

                InCallControlButton(
                    title: "Clavier",
                    systemImage: "circle.grid.3x3.fill"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "Audio",
                    systemImage: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2.fill",
                    isActive: isSpeakerOn,
                    activeTint: Theme.green
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isSpeakerOn.toggle()
                }
            }

            HStack(spacing: Layout.controlsColumnSpacing) {
                InCallControlButton(
                    title: "Ajouter",
                    systemImage: "plus"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "FaceTime",
                    systemImage: "video.fill"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "Contacts",
                    systemImage: "person.crop.circle"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .accessibilityElement(children: .contain)
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

#if canImport(UIKit)
private struct InCallControlButton: View {
    let title: String
    let systemImage: String
    var isActive: Bool = false
    var activeTint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isActive ? activeTint : .white)
                    .frame(width: 56, height: 56)
                    .modifier(GlassControlModifier(isActive: isActive, activeTint: activeTint))

                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct GlassControlModifier: ViewModifier {
    let isActive: Bool
    let activeTint: Color

    func body(content: Content) -> some View {
        if isActive {
            content.glassEffect(.regular.tint(activeTint.opacity(0.35)).interactive(), in: .circle)
        } else {
            content.glassEffect(.regular.interactive(), in: .circle)
        }
    }
}
#endif

#Preview {
    InCallView(appState: AppState.shared)
}
