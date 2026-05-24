import SwiftUI

struct HomeBackgroundLayer: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.green.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.accentColor.opacity(0.10), .clear],
                center: .init(x: 0.5, y: 0.85),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }
}
