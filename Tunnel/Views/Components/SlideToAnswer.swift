import SwiftUI

struct SlideToAnswer: View {
    private enum SliderConstants {
        static let height: CGFloat = 56
        static let knobSize: CGFloat = 48
        static let horizontalPadding: CGFloat = 4
        static let completionRatio: CGFloat = 0.82
    }

    let onAnswer: () -> Void
    @State private var knobOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxTravel = max(
                0,
                trackWidth - SliderConstants.knobSize - (SliderConstants.horizontalPadding * 2)
            )

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.2))

                Text("glisser pour répondre")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(knobOffset > maxTravel * 0.35 ? 0.45 : 1.0))
                    .frame(maxWidth: .infinity, alignment: .center)

                Circle()
                    .fill(.white)
                    .frame(width: SliderConstants.knobSize, height: SliderConstants.knobSize)
                    .overlay {
                        Image(systemName: "phone.fill")
                            .font(.headline)
                            .foregroundStyle(.black.opacity(0.85))
                    }
                    .offset(x: knobOffset + SliderConstants.horizontalPadding)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                knobOffset = min(max(0, value.translation.width), maxTravel)
                            }
                            .onEnded { _ in
                                let completion = maxTravel == 0 ? 0 : knobOffset / maxTravel
                                if completion >= SliderConstants.completionRatio {
                                    onAnswer()
                                }

                                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                    knobOffset = 0
                                }
                            }
                    )
            }
            .frame(height: SliderConstants.height)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Glisser pour répondre à l'appel")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Répondre") {
                onAnswer()
            }
        }
        .frame(height: SliderConstants.height)
    }
}

#Preview {
    SlideToAnswer(onAnswer: {})
        .padding()
        .background(.black)
}
