import SwiftUI

/// Premium home screen with proper hierarchy, visual balance, and iOS-grade polish.
struct HomeView: View {
    @Bindable var appState: AppState
    @State private var pulseRing = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Hero icon
                heroIcon
                    .padding(.bottom, 40)

                // Title block
                VStack(spacing: 8) {
                    Text("Tunnel")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                        .tracking(-0.5)

                    Text("Sortir d'une conversation en un geste.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Primary CTA
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
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.80, blue: 0.36),
                                Color(red: 0.16, green: 0.70, blue: 0.30)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(red: 0.16, green: 0.70, blue: 0.30).opacity(0.35), radius: 16, x: 0, y: 8)
                }
                .buttonStyle(PressableCTAStyle())

                // Secondary actions
                HStack(spacing: 0) {
                    secondaryButton(
                        icon: "hand.tap.fill",
                        label: "Back Tap",
                        action: { appState.openOnboarding() }
                    )

                    Divider()
                        .frame(height: 28)
                        .overlay(.separator)

                    secondaryButton(
                        icon: "gearshape.fill",
                        label: "Réglages",
                        action: { appState.openSettings() }
                    )
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Subtle green gradient tint (echoes the CTA)
            RadialGradient(
                colors: [
                    Color(red: 0.16, green: 0.70, blue: 0.30).opacity(0.12),
                    .clear
                ],
                center: .init(x: 0.5, y: 0.25),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)
        }
    }

    // MARK: - Hero icon

    private var heroIcon: some View {
        ZStack {
            // Pulsing ring
            Circle()
                .stroke(Color(red: 0.16, green: 0.70, blue: 0.30).opacity(0.20), lineWidth: 1)
                .frame(width: 160, height: 160)
                .scaleEffect(pulseRing ? 1.1 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.0).repeatForever(autoreverses: false),
                    value: pulseRing
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.80, blue: 0.36),
                            Color(red: 0.14, green: 0.62, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color(red: 0.16, green: 0.70, blue: 0.30).opacity(0.4), radius: 20, x: 0, y: 10)
                .overlay {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                }
        }
        .onAppear { pulseRing = true }
    }

    // MARK: - Secondary button

    private func secondaryButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PressableCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

#Preview {
    HomeView(appState: AppState.shared)
}
