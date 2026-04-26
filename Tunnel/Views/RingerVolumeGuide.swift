import SwiftUI
import UIKit

/// Étapes pour entendre la sonnerie au bon niveau (réglage iOS, pas l’app Untunnel).
enum RingerVolumeGuide {
    static let title = "Volume de la sonnerie"
    static let lead =
        "Untunnel utilise la sonnerie système comme un vrai appel. Si c’est trop discret, règle le volume iPhone (sonnerie, pas la musique) :"

    static let steps: [String] = [
        "Ouvre l’app Réglages (icône grise).",
        "Touche Sons et vibrations.",
        "Sous Sonnerie et alertes, monte le curseur vers la droite.",
        "Pendant que le faux appel sonne, les boutons + / – sur le côté règlent souvent la sonnerie.",
        "Si l’interrupteur au-dessus du volume est orange (mode silencieux), la sonnerie peut être coupée : repasse-le pour entendre le son.",
    ]

    /// Page Apple (Safari) si les raccourcis système ne répondent pas.
    static let appleSupportURL = URL(string: "https://support.apple.com/guide/iphone/iph6113603f2/ios")!
}

// MARK: - Liens vers Réglages / Raccourcis

/// Ouverture de l’app Réglages ou Raccourcis. `App-prefs:` n’est **pas** documenté par Apple : selon la version iOS, ça peut ne rien faire.
enum SystemSettingsOpener {
    /// Schéma public de l’app Raccourcis.
    private static let shortcutsApp = URL(string: "shortcuts://")!

    /// Tentative d’ouverture directe de l’écran Sons (non officiel).
    private static let soundsAppPrefs = URL(string: "App-prefs:root=Sounds")
    private static let soundsLegacyPrefs = URL(string: "prefs:root=Sounds")

    @MainActor
    static func openShortcutsApp() {
        UIApplication.shared.open(shortcutsApp, options: [:], completionHandler: nil)
    }

    @MainActor
    static func openSoundsSettings() {
        guard let primary = soundsAppPrefs else { return }
        UIApplication.shared.open(primary, options: [:]) { success in
            guard !success, let fallback = soundsLegacyPrefs else { return }
            Task { @MainActor in
                UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
            }
        }
    }
}

// MARK: - Numbered steps (réutilisable)

struct RingerVolumeNumberedSteps: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color.accentColor.opacity(0.12), in: .circle)

                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Boutons Réglages + Raccourcis + aide Apple

struct RingerVolumeSystemLinks: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                SystemSettingsOpener.openSoundsSettings()
            } label: {
                Label("Ouvrir Réglages › Sons et vibrations", systemImage: "speaker.wave.3.fill")
            }
            .accessibilityHint("Essaie d’ouvrir l’app Réglages sur la page Sons")

            Button {
                SystemSettingsOpener.openShortcutsApp()
            } label: {
                Label("Ouvrir l’app Raccourcis", systemImage: "square.grid.2x2.fill")
            }
            .accessibilityHint("Ouvre l’app Raccourcis pour créer ou modifier des raccourcis")

            Link(destination: RingerVolumeGuide.appleSupportURL) {
                Label("Aide Apple : volume et sonnerie", systemImage: "safari")
            }
            .font(.subheadline)
        }
    }
}
