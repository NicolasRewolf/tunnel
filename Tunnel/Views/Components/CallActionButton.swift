import SwiftUI
import UIKit

struct CallActionButton: View {
    let systemImage: String
    let backgroundColor: Color
    let accessibilityLabel: String
    let title: String?
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: didTapButton) {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(PressableCircleButtonStyle())
            .accessibilityLabel(accessibilityLabel)

            if let title {
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.88))
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
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 40) {
        CallActionButton(
            systemImage: "phone.down.fill",
            backgroundColor: .red,
            accessibilityLabel: "Raccrocher",
            title: "Refuser",
            action: {}
        )

        CallActionButton(
            systemImage: "phone.fill",
            backgroundColor: .green,
            accessibilityLabel: "Répondre",
            title: "Accepter",
            action: {}
        )
    }
    .padding()
    .background(.black)
}
