import SwiftUI

/// iOS 26 Liquid Glass home screen.
/// Uses `.buttonStyle(.glassProminent)` and `.buttonStyle(.glass)` for native Apple feel.
struct HomeView: View {
    @Bindable var appState: AppState
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
                        .font(.system(size: 44, weight: .bold, design: .default))
                        .tracking(-0.8)

                    Text("Sortir d'une conversation en un geste.")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Primary CTA — Liquid Glass prominent button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    appState.triggerFakeCallNow()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Lancer un faux appel")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .tint(Color(red: 0.20, green: 0.78, blue: 0.35))

                // Secondary glass buttons
                HStack(spacing: 12) {
                    Button {
                        appState.openOnboarding()
                    } label: {
                        Label("Raccourcis", systemImage: "hand.tap.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    Button {
                        appState.openSettings()
                    } label: {
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

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.15),
                    .clear
                ],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.10),
                    .clear
                ],
                center: .init(x: 0.5, y: 0.85),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Hero icon

    private var heroIcon: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .stroke(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.25), lineWidth: 1)
                .frame(width: 170, height: 170)
                .scaleEffect(pulseRing ? 1.12 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false),
                    value: pulseRing
                )

            // Middle pulsing ring (staggered)
            Circle()
                .stroke(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.35), lineWidth: 1)
                .frame(width: 150, height: 150)
                .scaleEffect(pulseRing ? 1.15 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(0.6),
                    value: pulseRing
                )

            // Core button
            Image(systemName: "phone.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 130, height: 130)
                .glassEffect(
                    .regular.tint(Color(red: 0.20, green: 0.78, blue: 0.35)),
                    in: .circle
                )
                .shadow(color: Color(red: 0.16, green: 0.70, blue: 0.30).opacity(0.5), radius: 22, x: 0, y: 10)
        }
        .onAppear { pulseRing = true }
    }
}

#Preview {
    HomeView(appState: AppState.shared)
}
