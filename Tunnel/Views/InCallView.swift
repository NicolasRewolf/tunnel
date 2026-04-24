import SwiftUI
import UIKit

/// Pixel-clone of iOS 26 Phone.app in-call UI.
/// Rendered after CallKit hands off control (user tapped Accept).
///
/// Goal: visually indistinguishable from the System In-Call UI that iOS draws
/// automatically when the app is not foregrounded (i.e. locked device case).
/// This way the transition CallKit → app is invisible to the user.
///
/// iOS 26 fidelity notes:
///  - Controls use Liquid Glass (`.glassEffect(.regular, in: .circle)`) to
///    match Phone.app's material — a flat gray fill is the #1 visual tell.
///  - Active toggle state = solid white background with black icon (Phone.app).
///  - Background is a blurred, desaturated-toward-black render of the contact
///    photo when one exists (matches Phone.app since iOS 17's redesign).
///  - Name typography: 32pt semibold. Subtitle: 17pt @ 0.65 alpha. Timer:
///    17pt @ 0.85 alpha, monospaced digits.
///  - Avatar gets a hairline white stroke + drop shadow for iOS 26 depth.
struct InCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 180
        static let topPadding: CGFloat = 56
        static let nameTopGap: CGFloat = 18
        static let subtitleTopGap: CGFloat = 4
        static let timerTopGap: CGFloat = 8
        static let endButtonSize: CGFloat = 80
        static let controlButtonSize: CGFloat = 82
        static let controlsHorizontalPadding: CGFloat = 28
        static let controlsRowSpacing: CGFloat = 28
        static let controlsColumnSpacing: CGFloat = 12
        static let controlsBottomGap: CGFloat = 28
        static let bottomPadding: CGFloat = 10
    }

    let appState: AppState
    @State private var callStartDate = Date()
    @State private var isMuted = false
    @State private var isSpeakerOn = false

    var body: some View {
        ZStack {
            backgroundLayer

            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Spacer().frame(height: Layout.topPadding)

                    contactAvatar

                    Text(appState.config.contactName)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.top, Layout.nameTopGap)
                        .padding(.horizontal, 24)

                    if !appState.config.contactSubtitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(appState.config.contactSubtitle)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                            .padding(.top, Layout.subtitleTopGap)
                    }

                    TimelineView(.periodic(from: callStartDate, by: 1)) { timeline in
                        Text(durationLabel(for: timeline.date))
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85))
                            .monospacedDigit()
                    }
                    .padding(.top, Layout.timerTopGap)

                    Spacer(minLength: 0)

                    controlsGrid
                        .padding(.horizontal, Layout.controlsHorizontalPadding)

                    Spacer().frame(height: Layout.controlsBottomGap)

                    endCallButton
                        .padding(.bottom, max(Layout.bottomPadding, proxy.safeAreaInsets.bottom + 8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .statusBarHidden(false)
        .preferredColorScheme(.dark)
        .onAppear { callStartDate = Date() }
    }

    // MARK: - Background

    /// When the contact has a custom photo, render it as a heavily blurred
    /// backdrop with a dark gradient overlay — Phone.app's signature since
    /// iOS 17. Fall back to pure black for the default avatar case so the
    /// controls stay legible.
    @ViewBuilder
    private var backgroundLayer: some View {
        if let data = appState.config.contactImageData,
           let uiImage = UIImage(data: data) {
            ZStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 80)
                    .saturation(1.1)

                LinearGradient(
                    colors: [
                        .black.opacity(0.25),
                        .black.opacity(0.55),
                        .black.opacity(0.78),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        } else {
            Color.black.ignoresSafeArea()
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var contactAvatar: some View {
        Group {
            if let data = appState.config.contactImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.30), Color(white: 0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "person.fill")
                        .font(.system(size: 88, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: Layout.avatarSize, height: Layout.avatarSize)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.45), radius: 24, y: 10)
    }

    // MARK: - End button

    private var endCallButton: some View {
        Button(action: endCall) {
            Image(systemName: "phone.down.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Layout.endButtonSize, height: Layout.endButtonSize)
                .background(Circle().fill(Theme.red))
                .shadow(color: Theme.red.opacity(0.35), radius: 16, y: 6)
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
                    title: "Contact",
                    systemImage: "person.crop.circle.fill",
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

/// Phone.app-styled toggle button with iOS 26 Liquid Glass.
///
/// - Inactive: glass material circle, white icon — picks up ambient color
///   from the blurred background when a contact photo is set.
/// - Active: solid white circle, black icon (= Phone.app toggle convention).
private struct InCallControlButton: View {
    let title: String
    let systemImage: String
    let size: CGFloat
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                iconContainer

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

    @ViewBuilder
    private var iconContainer: some View {
        if isActive {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.black)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.white))
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .glassEffect(.regular.tint(.black.opacity(0.18)), in: .circle)
                .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
        }
    }
}

#Preview {
    InCallView(appState: AppState.shared)
}
