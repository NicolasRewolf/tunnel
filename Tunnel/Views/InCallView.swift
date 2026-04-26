import SwiftUI
import UIKit

/// In-call screen après acceptation CallKit.
///
/// Layout fidèle à Phone.app iOS 26 :
///  - Header haut-gauche : avatar (96) + VStack timer (petit, muted) puis nom (gros, blanc)
///  - Grid 2×3 en bas, la case centre-bas est le bouton Raccrocher rouge
///  - Fond flouté dérivé de la photo du contact si présente, sinon noir
///
/// Principe de layout : **un seul endroit gère le padding horizontal** — sur la
/// VStack racine (`.padding(.horizontal, 24)`). Plus de `GeometryReader`, plus
/// de tailles dérivées de la hauteur d'écran. Les tailles sont fixes et
/// fonctionnent sur tous les iPhones (SE 375pt → Pro Max 430pt).
/// Dynamic Type via `@ScaledMetric` sur les fonts uniquement.
struct InCallView: View {
    let appState: AppState

    @State private var callStartDate = Date()
    @State private var isMuted = false
    @State private var isSpeakerOn = false

    @ScaledMetric(relativeTo: .largeTitle) private var nameFontSize: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var timerFontSize: CGFloat = 17
    @ScaledMetric(relativeTo: .caption) private var labelFontSize: CGFloat = 12

    private enum Metrics {
        static let horizontalMargin: CGFloat = 24
        static let topMargin: CGFloat = 60
        static let bottomMargin: CGFloat = 12

        static let avatarSize: CGFloat = 96
        static let headerSpacing: CGFloat = 16

        static let controlButtonSize: CGFloat = 100
        static let controlIconSize: CGFloat = 28
        static let endIconSize: CGFloat = 30
        static let controlsRowSpacing: CGFloat = 24
        static let controlsColumnSpacing: CGFloat = 8
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: 0)
                controlsGrid
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, Metrics.horizontalMargin)
            .padding(.top, Metrics.topMargin)
            .padding(.bottom, Metrics.bottomMargin)
        }
        .preferredColorScheme(.dark)
        .onAppear { callStartDate = Date() }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if let data = appState.config.contactImageData,
           let uiImage = UIImage(data: data) {
            // Color.black = vue "layout neutre" qui prend exactement la taille offerte
            // par le parent. Les overlays (image + gradient) sont CLIPPÉS à ses bounds,
            // donc `scaledToFill` ne peut pas déborder et casser le layout parent.
            Color.black
                .overlay(
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 80)
                        .saturation(1.1)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.25),
                            .black.opacity(0.55),
                            .black.opacity(0.78),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        } else {
            Color.black.ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Metrics.headerSpacing) {
            contactAvatar

            VStack(alignment: .leading, spacing: 4) {
                TimelineView(.periodic(from: callStartDate, by: 1)) { timeline in
                    Text(durationLabel(for: timeline.date))
                        .font(.system(size: timerFontSize, weight: .regular))
                        .foregroundStyle(.white.opacity(0.60))
                        .monospacedDigit()
                }

                Text(appState.config.contactName)
                    .font(.system(size: nameFontSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer(minLength: 0)
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
                        .font(.system(size: Metrics.avatarSize * 0.48, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: Metrics.avatarSize, height: Metrics.avatarSize)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
    }

    // MARK: - Controls grid (6 cases, end-call case centre-bas)

    private var controlsGrid: some View {
        Grid(
            horizontalSpacing: Metrics.controlsColumnSpacing,
            verticalSpacing: Metrics.controlsRowSpacing
        ) {
            GridRow {
                InCallControlButton(
                    title: "Audio",
                    systemImage: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2.fill",
                    size: Metrics.controlButtonSize,
                    iconFont: Metrics.controlIconSize,
                    labelFont: labelFontSize,
                    kind: .toggle(isActive: isSpeakerOn)
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isSpeakerOn.toggle()
                }

                InCallControlButton(
                    title: "FaceTime",
                    systemImage: "video.fill",
                    size: Metrics.controlButtonSize,
                    iconFont: Metrics.controlIconSize,
                    labelFont: labelFontSize
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "Muet",
                    systemImage: "mic.slash.fill",
                    size: Metrics.controlButtonSize,
                    iconFont: Metrics.controlIconSize,
                    labelFont: labelFontSize,
                    kind: .toggle(isActive: isMuted)
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isMuted.toggle()
                }
            }

            GridRow {
                InCallControlButton(
                    title: "Plus",
                    systemImage: "ellipsis",
                    size: Metrics.controlButtonSize,
                    iconFont: Metrics.controlIconSize,
                    labelFont: labelFontSize
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                InCallControlButton(
                    title: "Raccrocher",
                    systemImage: "phone.down.fill",
                    size: Metrics.controlButtonSize,
                    iconFont: Metrics.endIconSize,
                    labelFont: labelFontSize,
                    kind: .destructive,
                    action: endCall
                )

                InCallControlButton(
                    title: "Clavier",
                    systemImage: "circle.grid.3x3.fill",
                    size: Metrics.controlButtonSize,
                    iconFont: Metrics.controlIconSize,
                    labelFont: labelFontSize
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

/// Bouton de contrôle style Phone.app iOS 26.
///  - `.standard` : glass material + icône blanche (défaut)
///  - `.toggle(isActive:)` : actif → cercle blanc + icône noire
///  - `.destructive` : cercle rouge plein + icône blanche (bouton Raccrocher)
private struct InCallControlButton: View {
    enum Kind {
        case standard
        case toggle(isActive: Bool)
        case destructive
    }

    let title: String
    let systemImage: String
    let size: CGFloat
    let iconFont: CGFloat
    let labelFont: CGFloat
    var kind: Kind = .standard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                iconContainer

                Text(title)
                    .font(.system(size: labelFont, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActiveTrait)
    }

    @ViewBuilder
    private var iconContainer: some View {
        switch kind {
        case .destructive:
            Image(systemName: systemImage)
                .font(.system(size: iconFont, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Theme.red))
                .shadow(color: Theme.red.opacity(0.35), radius: 14, y: 6)

        case .toggle(isActive: true):
            Image(systemName: systemImage)
                .font(.system(size: iconFont, weight: .regular))
                .foregroundStyle(.black)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.white))

        case .standard, .toggle(isActive: false):
            Image(systemName: systemImage)
                .font(.system(size: iconFont, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .glassEffect(.regular.tint(.black.opacity(0.18)), in: .circle)
                .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
        }
    }

    private var isActiveTrait: AccessibilityTraits {
        if case .toggle(isActive: true) = kind { return [.isSelected] }
        return []
    }
}

#Preview {
    InCallView(appState: AppState.shared)
}
