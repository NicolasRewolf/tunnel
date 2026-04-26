import SwiftUI

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

    /// Page Apple « volume et sonnerie » (s’ouvre dans Safari).
    static let appleSupportURL = URL(string: "https://support.apple.com/guide/iphone/iph6113603f2/ios")!
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
