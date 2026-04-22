import SwiftUI

struct OnboardingView: View {
    let appState: AppState

    private let steps = [
        "Ouvre Réglages > Accessibilité > Toucher > Toucher au dos.",
        "Choisis Double toucher ou Triple toucher.",
        "Sélectionne Raccourci puis Déclencher Tunnel."
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active le geste Back Tap")
                        .font(.largeTitle.bold())
                    Text("Configure Tunnel en 1 minute pour lancer un faux appel sans ouvrir l'app.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1).")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(step)
                                .font(.body)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Astuce")
                        .font(.headline)
                    Text("Tu peux déjà tester Tunnel avec le bouton Déclencher maintenant pendant que tu configures Back Tap.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Back Tap est activé") {
                    appState.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Configurer plus tard") {
                    appState.dismissOnboarding()
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    OnboardingView(appState: AppState.shared)
}
