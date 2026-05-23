import SwiftUI

/// One-shot sheet after updating from a prior version (Shortcuts discoverability).
struct ShortcutAnnouncementSheet: View {
    let onOpenShortcuts: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 10) {
                Text("Toucher au dos, plus fiable")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("Si « Déclencher Untunnel » n’apparaît pas dans Réglages › Accessibilité › Toucher au dos, ouvre l’app Raccourcis : tu pourras l’ajouter en un tap.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Button(action: onOpenShortcuts) {
                    HStack(spacing: 8) {
                        Text("Ouvrir Raccourcis")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .tint(Color.accentColor)

                Button("Plus tard", action: onDismiss)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .padding(.top, 24)
    }
}
