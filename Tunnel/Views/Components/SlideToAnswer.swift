import SwiftUI

/// iOS-style "Slide to answer" component mimicking the lock-screen incoming call UI.
struct SlideToAnswer: View {
    private enum Layout {
        static let height: CGFloat = 68
        static let knobSize: CGFloat = 60
        static let padding: CGFloat = 4
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
                // Track background
                Capsule()
                    .fill(.white.opacity(0.16))

                // Shimmering "glisser" label
                Text("glisser pour répondre")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white,
                                .white.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .shadow(.inner(color: .black.opacity(0), radius: 0))
                    )
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

                // Circle knob
                Circle()
                    .fill(Color(red: 0.22, green: 0.80, blue: 0.36))
                    .frame(width: Layout.knobSize, height: Layout.knobSize)
                    .overlay {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                    .offset(x: knobOffset + Layout.padding)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let translation = min(max(0, value.translation.width), maxTravel)
                                knobOffset = translation
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
