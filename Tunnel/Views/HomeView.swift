import SwiftUI

/// Home screen: hero icon, name, single CTA, two secondary buttons.
struct HomeView: View {
    let appState: AppState
    @State private var pulseRing = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                heroIcon
                    .padding(.bottom, 40)

                VStack(spacing: 8) {
                    Text("Tunnel")
                        .font(.system(size: 44, weight: .bold))
                        .tracking(-0.8)

                    Text("Sortir d'une conversation en un geste.")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                Button(action: triggerCall) {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Sortir du tunnel")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .tint(Theme.green)

                HStack(spacing: 12) {
                    Button { appState.openOnboarding() } label: {
                        Label("Raccourcis", systemImage: "hand.tap.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    Button { appState.openSettings() } label: {
                        Label("Réglages", systemImage: "gearshape.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Private

    private func triggerCall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        appState.triggerFakeCallNow()
    }

    private var backgroundLayer: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.green.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.accentColor.opacity(0.10), .clear],
                center: .init(x: 0.5, y: 0.85),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }

    private var heroIcon: some View {
        ZStack {
            Circle()
                .stroke(Theme.green.opacity(0.25), lineWidth: 1)
                .frame(width: 170, height: 170)
                .scaleEffect(pulseRing ? 1.12 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false),
                    value: pulseRing
                )

            Circle()
                .stroke(Theme.green.opacity(0.35), lineWidth: 1)
                .frame(width: 150, height: 150)
                .scaleEffect(pulseRing ? 1.15 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(0.6),
                    value: pulseRing
                )

            Image(systemName: "phone.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 130, height: 130)
                .glassEffect(.regular.tint(Theme.green), in: .circle)
                .shadow(color: Theme.greenDeep.opacity(0.5), radius: 22, x: 0, y: 10)
        }
        .onAppear { pulseRing = true }
    }
}

#Preview {
    HomeView(appState: AppState.shared)
}
