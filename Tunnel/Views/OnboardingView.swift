import SwiftUI

/// iOS 26 Liquid Glass onboarding screen.
struct OnboardingView: View {
    let appState: AppState

    private let steps: [(number: String, title: String, subtitle: String)] = [
        ("1", "Réglages iPhone", "Accessibilité › Toucher › Toucher au dos"),
        ("2", "Choisis un geste", "Double toucher ou Triple toucher"),
        ("3", "Associe Tunnel", "Raccourci › Déclencher Tunnel")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Active Back Tap")
                            .font(.system(size: 34, weight: .bold))
                            .tracking(-0.5)

                        Text("Déclenche un faux appel en tapotant l'arrière de ton iPhone.")
                            .font(.system(size: 17))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Steps with Liquid Glass container
                    VStack(spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            stepRow(step)

                            if index < steps.count - 1 {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }

                    // Tip row
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.18))
                            .padding(.top, 2)

                        Text("Tu peux tester Tunnel à tout moment avec le bouton **Lancer un faux appel** depuis l'accueil.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 40)

                    VStack(spacing: 10) {
                        Button {
                            appState.completeOnboarding()
                        } label: {
                            Text("J'ai configuré Back Tap")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.extraLarge)
                        .tint(Color.accentColor)

                        Button("Configurer plus tard") {
                            appState.dismissOnboarding()
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarBackButtonHidden(true)
        }
    }

    private func stepRow(_ step: (number: String, title: String, subtitle: String)) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 34, height: 34)

                Text(step.number)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.system(size: 17, weight: .medium))

                Text(step.subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

#Preview {
    OnboardingView(appState: AppState.shared)
}
