import SwiftUI

/// iOS 26 Liquid Glass "Slide to answer" component.
struct SlideToAnswer: View {
    private enum Layout {
        static let height: CGFloat = 70
        static let knobSize: CGFloat = 60
        static let padding: CGFloat = 5
        static let completionRatio: CGFloat = 0.82
    }

    let onAnswer: () -> Void
    @State private var knobOffset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxTravel = max(0, trackWidth - Layout.knobSize - (Layout.padding * 2))
            let progress = maxTravel == 0 ? 0 : knobOffset / maxTravel

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular, in: .capsule)

                Text("glisser pour répondre")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white)
                    .opacity(1.0 - progress * 1.5)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.3), location: 0),
                                .init(color: .white, location: shimmerPhase),
                                .init(color: .white.opacity(0.3), location: min(1, shimmerPhase + 0.2))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            shimmerPhase = 1.2
                        }
                    }

                Image(systemName: "phone.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: Layout.knobSize, height: Layout.knobSize)
                    .glassEffect(
                        .regular.tint(Theme.green).interactive(),
                        in: .circle
                    )
                    .offset(x: knobOffset + Layout.padding)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                knobOffset = min(max(0, value.translation.width), maxTravel)
                            }
                            .onEnded { _ in
                                let completion = maxTravel == 0 ? 0 : knobOffset / maxTravel
                                if completion >= Layout.completionRatio {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    onAnswer()
                                }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    knobOffset = 0
                                }
                            }
                    )
            }
            .frame(height: Layout.height)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Glisser pour répondre à l'appel")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Répondre") {
                onAnswer()
            }
        }
        .frame(height: Layout.height)
    }
}

#Preview {
    SlideToAnswer(onAnswer: {})
        .padding(24)
        .background(.black)
}
