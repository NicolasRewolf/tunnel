import SwiftUI

/// Onboarding explaining how to trigger a fake call discreetly — the core value of Tunnel.
/// Surfaces the primary method (Back Tap) and a zero-setup alternative (Siri).
struct OnboardingView: View {
    let appState: AppState

    private let steps: [Step] = [
        Step(
            number: "1",
            title: "Ouvre les Réglages iOS",
            path: "Accessibilité › Toucher › Toucher au dos"
        ),
        Step(
            number: "2",
            title: "Choisis ton geste",
            path: "Double toucher ou Triple toucher"
        ),
        Step(
            number: "3",
            title: "Associe Tunnel",
            path: "Raccourci › Lancer un faux appel"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    stepsCard
                    siriAlternative

                    Spacer(minLength: 32)

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
            Text("Déclenche sans toucher ton iPhone")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)

            Text("Deux tapes à l'arrière de ton iPhone suffisent à lancer un faux appel — même dans ta poche, au milieu d'une conversation.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    // MARK: - Steps card

    private var stepsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepRow(step)

                if index < steps.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }

    private func stepRow(_ step: Step) -> some View {
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

                Text(step.path)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Siri alternative

    private var siriAlternative: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("Ou par la voix")
                    .font(.system(size: 15, weight: .semibold))

                Text("Dis à Siri : « Lance Tunnel » ou « Tunnel appelle-moi ».")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                appState.completeOnboarding()
            } label: {
                Text("C'est prêt")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(Color.accentColor)

            Button("Plus tard") {
                appState.dismissOnboarding()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Model

    private struct Step {
        let number: String
        let title: String
        let path: String
    }
}

#Preview {
    OnboardingView(appState: AppState.shared)
}
