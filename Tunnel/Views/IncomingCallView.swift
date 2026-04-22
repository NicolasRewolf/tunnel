import SwiftUI

/// Pixel-perfect iOS 17 incoming call screen.
/// Matches Apple's native call UI with proper spacing, typography, and controls.
struct IncomingCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 132
        static let topPadding: CGFloat = 60
        static let bottomPadding: CGFloat = 48
        static let secondaryRowSpacing: CGFloat = 38
        static let primaryRowSpacing: CGFloat = 80
    }

    let appState: AppState

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                // Top: contact identity block
                Spacer()
                    .frame(height: Layout.topPadding)

                contactAvatar
                    .padding(.bottom, 22)

                Text(appState.config.contactName)
                    .font(.system(size: 32, weight: .semibold, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 24)

                Text(appState.config.contactSubtitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 6)

                Spacer()

                // Bottom: action buttons
                actionArea
                    .padding(.horizontal, 32)
                    .padding(.bottom, Layout.bottomPadding)
            }
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.10, blue: 0.14),
                    Color(red: 0.02, green: 0.03, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle top spotlight (like iOS native call UI)
            RadialGradient(
                colors: [Color.white.opacity(0.08), .clear],
                center: .init(x: 0.5, y: 0.15),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            .blendMode(.screen)
        }
    }

    // MARK: - Avatar

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
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 58, weight: .regular))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        }
    }

    private func avatarImage(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: Layout.avatarSize, height: Layout.avatarSize)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 4)
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionArea: some View {
        if appState.config.useSlideToAnswer {
            slideToAnswerLayout
        } else {
            nativeButtonsLayout
        }
    }

    private var nativeButtonsLayout: some View {
        VStack(spacing: 28) {
            // Secondary row (like iOS "Remind Me" / "Message")
            HStack(spacing: Layout.secondaryRowSpacing) {
                secondaryAction(icon: "alarm.fill", label: "Me rappeler")
                secondaryAction(icon: "message.fill", label: "Message")
            }
            .padding(.horizontal, 40)

            // Primary row (decline + accept)
            HStack(spacing: Layout.primaryRowSpacing) {
                CallActionButton(
                    systemImage: "phone.down.fill",
                    style: .decline,
                    accessibilityLabel: "Refuser l'appel",
                    title: "Refuser",
                    action: { appState.endCall() }
                )

                CallActionButton(
                    systemImage: "phone.fill",
                    style: .accept,
                    accessibilityLabel: "Accepter l'appel",
                    title: "Accepter",
                    action: { appState.answerCall() }
                )
            }
        }
    }

    private var slideToAnswerLayout: some View {
        VStack(spacing: 20) {
            SlideToAnswer { appState.answerCall() }

            Button(action: { appState.endCall() }) {
                Text("Refuser")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    private func secondaryAction(icon: String, label: String) -> some View {
        // Non-functional decorative buttons to match Apple's call layout.
        // They visually ground the app as a "real" call screen.
        VStack(spacing: 6) {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.white.opacity(0.92))
                }

            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    IncomingCallView(appState: AppState.shared)
}
