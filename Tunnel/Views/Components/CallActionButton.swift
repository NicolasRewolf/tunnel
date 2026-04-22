import SwiftUI
import UIKit

/// iOS 26 Liquid Glass call action button.
/// Uses `.glassEffect()` with tinted colors and interactive feedback.
struct CallActionButton: View {
    enum Size {
        case regular
        case small

        var diameter: CGFloat {
            switch self {
            case .regular: return 78
            case .small: return 62
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .regular: return 30
            case .small: return 22
            }
        }
    }

    enum Style {
        case accept
        case decline
        case secondary

        var tint: Color? {
            switch self {
            case .accept: return Color(red: 0.20, green: 0.78, blue: 0.35)
            case .decline: return Color(red: 0.97, green: 0.26, blue: 0.28)
            case .secondary: return nil
            }
        }
    }

    let systemImage: String
    let style: Style
    let size: Size
    let accessibilityLabel: String
    let title: String?
    let action: () -> Void

    init(
        systemImage: String,
        style: Style,
        size: Size = .regular,
        accessibilityLabel: String,
        title: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.style = style
        self.size = size
        self.accessibilityLabel = accessibilityLabel
        self.title = title
        self.action = action
    }

    var body: some View {
        VStack(spacing: 10) {
            Button(action: didTapButton) {
                Image(systemName: systemImage)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: size.diameter, height: size.diameter)
                    .glassEffect(glassEffectStyle, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)

            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(minWidth: 80)
            }
        }
    }

    private var glassEffectStyle: Glass {
        if let tint = style.tint {
            return .regular.tint(tint).interactive()
        }
        return .regular.interactive()
    }

    private func didTapButton() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        action()
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.black, Color(red: 0.08, green: 0.10, blue: 0.14)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            HStack(spacing: 80) {
                CallActionButton(
                    systemImage: "phone.down.fill",
                    style: .decline,
                    accessibilityLabel: "Raccrocher",
                    title: "Refuser",
                    action: {}
                )

                CallActionButton(
                    systemImage: "phone.fill",
                    style: .accept,
                    accessibilityLabel: "Répondre",
                    title: "Accepter",
                    action: {}
                )
            }

            HStack(spacing: 40) {
                CallActionButton(
                    systemImage: "mic.slash.fill",
                    style: .secondary,
                    size: .small,
                    accessibilityLabel: "Silence",
                    title: "Silence",
                    action: {}
                )

                CallActionButton(
                    systemImage: "speaker.wave.2.fill",
                    style: .secondary,
                    size: .small,
                    accessibilityLabel: "Haut-parleur",
                    title: "Haut-parleur",
                    action: {}
                )
            }
        }
    }
}
