import SwiftUI

struct SettingsCallPreviewSection: View {
    let profile: CallProfile

    var body: some View {
        Section {
            CallProfilePreviewCard(profile: profile)
        } header: {
            Label("Aperçu", systemImage: "eye.fill")
        } footer: {
            Text("Visible aussi sur l’appel entrant.")
        }
    }
}

struct SettingsSoundSection: View {
    var body: some View {
        Section {
            Text(RingerVolumeGuide.lead)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RingerVolumeNumberedSteps(steps: RingerVolumeGuide.steps)

            Link(destination: RingerVolumeGuide.appleSupportURL) {
                Label("Guide Apple : sonnerie", systemImage: "safari")
            }
            .font(.subheadline)
        } header: {
            Label("Son", systemImage: "speaker.wave.2.fill")
        } footer: {
            Text("Réglage iOS — l’app n’y a pas accès.")
        }
    }
}

struct SettingsReactivitySection: View {
    @Binding var isReactiveModeEnabled: Bool

    var body: some View {
        Section {
            Toggle(isOn: $isReactiveModeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mode réactif")
                        .font(.body)
                    Text(isReactiveModeEnabled
                        ? "Déclenchement instantané, partout"
                        : "Déclenchement quand l’iPhone est réveillé")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Réactivité")
        } footer: {
            Text("Active : Bouton Action et Raccourcis répondent au quart de tour, même quand l’iPhone est verrouillé face contre la table. Coût : environ 5 à 10 % de batterie en plus par jour (audio silencieux maintenu en arrière-plan).\n\nDésactive : il faut réveiller l’iPhone (le retourner face vers toi, ou tapoter discrètement) avant de déclencher. Aucun coût batterie.")
        }
    }
}

struct SettingsHelpSection: View {
    let hasActionButton: Bool
    let onOpenOnboarding: () -> Void
    let onOpenPrivacy: () -> Void

    var body: some View {
        Section {
            SettingsNavigationRow(
                icon: "hand.tap.fill",
                label: "Déclencher sans ouvrir l’app",
                action: onOpenOnboarding
            )
            SettingsNavigationRow(
                icon: "arrow.up.right.square",
                label: "Ouvrir l’app Raccourcis",
                action: openShortcutsApp
            )
            SettingsNavigationRow(
                icon: "lock.shield.fill",
                label: "Confidentialité",
                action: onOpenPrivacy
            )
        } header: {
            Text("Aide")
        } footer: {
            Text(
                hasActionButton
                    ? "Toucher au dos, Bouton Action, Raccourcis : voir l’onboarding."
                    : "Toucher au dos, Raccourcis : voir l’onboarding."
            )
        }
    }

    private func openShortcutsApp() {
        guard let url = URL(string: "shortcuts://") else { return }
        UIApplication.shared.open(url)
    }
}

struct SettingsAboutSection: View {
    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 4) {
                Text("Untunnel")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Simulation locale. Aucune donnée personnelle ne quitte cet iPhone — seul un check de mise à jour quotidien interroge l’App Store.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
        } header: {
            Text("À propos")
        }
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                Text(label)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityLabel(label)
        .accessibilityHint("Ouvre \(label)")
    }
}
