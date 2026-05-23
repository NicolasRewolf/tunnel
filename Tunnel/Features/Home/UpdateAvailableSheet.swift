import SwiftUI

/// Soft App Store update prompt when a newer build is available.
struct UpdateAvailableSheet: View {
    let latestVersion: String
    let onUpdate: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 10) {
                Text("Nouvelle version disponible")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("Untunnel \(latestVersion) est sur l’App Store. Tu profiteras des dernières améliorations et corrections.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Button(action: onUpdate) {
                    HStack(spacing: 8) {
                        Text("Mettre à jour")
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
