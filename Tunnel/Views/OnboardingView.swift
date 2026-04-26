import SwiftUI

/// Onboarding focused on discreet, silent, tactile triggers.
/// No voice. No screen taps. Just physical gestures or pre-placed icons.
struct OnboardingView: View {
    let appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    volumeTipCard

                    primaryMethod
                    secondaryMethod
                    tertiaryMethod

                    Spacer(minLength: 24)

                    actions
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Déclenche sans toucher l'écran")
                .font(.title.weight(.bold))
                .tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)

            Text("Associe Tunnel à un geste ou à un bouton pour lancer un faux appel en silence, même main dans la poche.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    // MARK: - Sonnerie (réglages iPhone)

    private var volumeTipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            MethodCard(
                icon: "speaker.wave.3.fill",
                label: RingerVolumeGuide.title,
                description: RingerVolumeGuide.lead,
                steps: RingerVolumeGuide.steps,
                featured: true
            )

            Link(destination: RingerVolumeGuide.appleSupportURL) {
                Label("Aide Apple : volume et sonnerie", systemImage: "safari")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Method 1: Back Tap (featured)

    private var primaryMethod: some View {
        MethodCard(
            icon: "hand.tap.fill",
            label: "Toucher au dos",
            description: "Tapote 2 ou 3 fois l'arrière de ton iPhone. Le geste le plus invisible.",
            steps: [
                "Réglages › Accessibilité › Toucher › Toucher au dos",
                "Double toucher ou Triple toucher",
                "Raccourci › Déclencher Tunnel"
            ],
            featured: true
        )
    }

    // MARK: - Method 2: Action Button

    private var secondaryMethod: some View {
        MethodCard(
            icon: "button.horizontal.top.press.fill",
            label: "Bouton Action",
            description: "Sur iPhone 15 Pro et plus récent. Une seule pression du bouton latéral.",
            steps: [
                "Réglages › Bouton Action",
                "Glisse jusqu'à Raccourci",
                "Choisis Déclencher Tunnel"
            ],
            featured: false
        )
    }

    // MARK: - Method 3: Home Screen Shortcut

    private var tertiaryMethod: some View {
        MethodCard(
            icon: "square.grid.2x2.fill",
            label: "Icône raccourci",
            description: "Place un bouton Tunnel sur ton écran d'accueil, déguisé en icône neutre.",
            steps: [
                "Ouvre l'app Raccourcis d'iOS",
                "Crée un raccourci avec Déclencher Tunnel",
                "Partager › Ajouter à l'écran d'accueil"
            ],
            featured: false
        )
    }

    // MARK: - Actions

    private var actions: some View {
        Button {
            appState.goHome()
        } label: {
            Text("C'est prêt")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.extraLarge)
        .tint(Color.accentColor)
        .accessibilityLabel("Terminer l'onboarding et revenir à l'accueil")
    }
}

// MARK: - Method card

private struct MethodCard: View {
    let icon: String
    let label: String
    let description: String
    let steps: [String]
    let featured: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(featured ? Color.accentColor : Color.accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(featured ? .white : Color.accentColor)
                }

                Text(label)
                    .font(.headline)

                Spacer()
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        // Fixed size: sits inside a 18×18 circle, Dynamic
                        // Type would overflow the decorative badge.
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .background(Color.accentColor.opacity(0.12), in: .circle)

                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label). \(description)")
        .accessibilityHint("\(steps.count) étapes à suivre dans les Réglages")
    }
}

#Preview {
    OnboardingView(appState: AppState.shared)
}
