import SwiftUI

struct IncomingCallView: View {
    private enum Layout {
        static let contactSize: CGFloat = 122
        static let contentHorizontalPadding: CGFloat = 24
        static let infoTopSpacing: CGFloat = 72
        static let actionBottomPadding: CGFloat = 42
    }

    let appState: AppState
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.12),
                    Color(red: 0.09, green: 0.12, blue: 0.18),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.14), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 430
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: Layout.infoTopSpacing)

                Text("Appel entrant")
                    .font(.system(size: 14, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.64))
                    .padding(.bottom, 26)

                contactAvatar
                    .padding(.bottom, 20)

                Text(appState.config.contactName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                Text(appState.config.contactSubtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.bottom, 4)

                Text(appState.config.fakePhoneNumber)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.62))

                Spacer()

                if appState.config.useSlideToAnswer {
                    VStack(spacing: 14) {
                        SlideToAnswer {
                            appState.answerCall()
                        }

                        Button("Refuser") {
                            appState.endCall()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.78))
                    }
                    .padding(.bottom, Layout.actionBottomPadding)
                } else {
                    HStack(spacing: 84) {
                        CallActionButton(
                            systemImage: "phone.down.fill",
                            backgroundColor: .red,
                            accessibilityLabel: "Refuser l'appel",
                            title: "Refuser"
                        ) {
                            appState.endCall()
                        }

                        CallActionButton(
                            systemImage: "phone.fill",
                            backgroundColor: .green,
                            accessibilityLabel: "Accepter l'appel",
                            title: "Accepter"
                        ) {
                            appState.answerCall()
                        }
                        .scaleEffect(pulse ? 1.08 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: pulse
                        )
                    }
                    .padding(.bottom, Layout.actionBottomPadding)
                }
            }
            .padding(.horizontal, Layout.contentHorizontalPadding)
        }
        .statusBarHidden(true)
        .onAppear {
            pulse = true
        }
    }

    @ViewBuilder
    private var contactAvatar: some View {
        if let data = appState.config.contactImageData,
           let uiImage = UIImage(data: data) {
            avatarImage(uiImage)
        } else if let imageName = appState.config.contactImageName,
                  let uiImage = UIImage(named: imageName) {
            avatarImage(uiImage)
        } else {
            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: Layout.contactSize, height: Layout.contactSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
        }
    }

    private func avatarImage(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: Layout.contactSize, height: Layout.contactSize)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    IncomingCallView(appState: AppState.shared)
}
