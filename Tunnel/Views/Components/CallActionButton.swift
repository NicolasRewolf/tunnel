import SwiftUI
import UIKit

/// iOS-style circular call action button with optional label underneath.
/// Matches Apple's CallKit-style primary action buttons.
struct CallActionButton: View {
    enum Size {
        case regular // 72pt (primary accept/decline)
        case small   // 64pt (secondary actions)

        var diameter: CGFloat {
            switch self {
            case .regular: return 72
            case .small: return 64
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .regular: return 30
            case .small: return 24
            }
        }
    }

    enum Style {
        case accept     // green filled
        case decline    // red filled
        case secondary  // translucent white

        var background: AnyShapeStyle {
            switch self {
            case .accept:
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.80, blue: 0.36), Color(red: 0.16, green: 0.70, blue: 0.30)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            case .decline:
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.28, blue: 0.30), Color(red: 0.86, green: 0.16, blue: 0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            case .secondary:
                return AnyShapeStyle(Color.white.opacity(0.18))
            }
        }

        var iconColor: Color {
            .white
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
        VStack(spacing: 8) {
            Button(action: didTapButton) {
                Circle()
                    .fill(style.background)
                    .frame(width: size.diameter, height: size.diameter)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: size.iconSize, weight: .semibold))
                            .foregroundStyle(style.iconColor)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(PressableCircleButtonStyle())
            .accessibilityLabel(accessibilityLabel)

            if let title {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(minWidth: 80)
            }
        }
    }

    private func didTapButton() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        action()
    }
}

private struct PressableCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

#Preview {
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
    .padding()
    .background(.black)
}
