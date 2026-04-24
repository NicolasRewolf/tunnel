import SwiftUI
import UIKit

/// Pixel-clone of iOS 26 Phone.app in-call UI.
/// Rendered after CallKit hands off control (user tapped Accept).
///
/// Goal: visually indistinguishable from the System In-Call UI that iOS draws
/// automatically when the app is not foregrounded (i.e. locked device case).
/// This way the transition CallKit → app is invisible to the user.
struct InCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 108
        static let topPadding: CGFloat = 72
        static let bottomPadding: CGFloat = 44
        static let endButtonSize: CGFloat = 76
        static let controlButtonSize: CGFloat = 72
        static let controlsHorizontalPadding: CGFloat = 32
        static let controlsRowSpacing: CGFloat = 22
        static let controlsColumnSpacing: CGFloat = 16
    }

    let appState: AppState
    @State private var callStartDate = Date()
    @State private var isMuted = false
    @State private var isSpeakerOn = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: Layout.topPadding)

                contactAvatar
                    .padding(.bottom, 18)

                Text(appState.config.contactName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 24)

                if !appState.config.contactSubtitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(appState.config.contactSubtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .padding(.top, 2)
                }

                TimelineView(.periodic(from: callStartDate, by: 1)) { timeline in
                    Text(durationLabel(for: timeline.date))
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                        .monospacedDigit()
                }
                .padding(.top, 4)

                Spacer()

                controlsGrid
                    .padding(.horizontal, Layout.controlsHorizontalPadding)
                    .padding(.bottom, 32)

                endCallButton
                    .padding(.bottom, Layout.bottomPadding)
            }
        }
        .statusBarHidden(false)
        .preferredColorScheme(.dark)
        .onAppear { callStartDate = Date() }
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
            ZStack {
                Circle()
                    .fill(Color(white: 0.22))
                    .frame(width: Layout.avatarSize, height: Layout.avatarSize)

                Image(systemName: "person.fill")
                    .font(.system(size: 52, weight: .regular))
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
                .background(Circle().fill(Theme.red))
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
                    systemImage: "mic.slash.fill",
                    size: Layout.controlButtonSize,
                    isActive: isMuted
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isMuted.toggle()
                }

                InCallControlButton(
                    title: "Clavier",
                    systemImage: "circle.grid.3x3.fill",
                    size: Layout.controlButtonSize
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "Audio",
                    systemImage: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2.fill",
                    size: Layout.controlButtonSize,
                    isActive: isSpeakerOn
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isSpeakerOn.toggle()
                }
            }

            HStack(spacing: Layout.controlsColumnSpacing) {
                InCallControlButton(
                    title: "Ajouter",
                    systemImage: "plus",
                    size: Layout.controlButtonSize
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "FaceTime",
                    systemImage: "video.fill",
                    size: Layout.controlButtonSize
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "Contacts",
                    systemImage: "person.crop.circle",
                    size: Layout.controlButtonSize
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

// MARK: - Control Button

private struct InCallControlButton: View {
    let title: String
    let systemImage: String
    let size: CGFloat
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(isActive ? Color.black : .white)
                    .frame(width: size, height: size)
                    .background(
                        Circle().fill(isActive ? Color.white : Color(white: 0.22))
                    )

                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

#Preview {
    InCallView(appState: AppState.shared)
}
