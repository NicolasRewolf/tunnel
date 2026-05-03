import SwiftUI

/// Étapes pour entendre la sonnerie au bon niveau (réglage iOS, pas l’app Untunnel).
enum RingerVolumeGuide {
    static let title = "Volume de la sonnerie"
    static let lead =
        "Sonnerie système, comme un vrai appel. Si elle est trop discrète :"

    static let steps: [String] = [
        "Réglages › Sons et vibrations.",
        "Monte le curseur Sonnerie et alertes.",
        "Interrupteur Sonnerie/Silence (au-dessus du volume) : pas orange.",
    ]

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
