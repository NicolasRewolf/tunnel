import SwiftUI

/// Pixel-perfect iOS 26 incoming call screen using Liquid Glass.
struct IncomingCallView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 136
        static let topPadding: CGFloat = 56
        static let bottomPadding: CGFloat = 48
        static let secondaryRowSpacing: CGFloat = 44
        static let primaryRowSpacing: CGFloat = 72
    }

    let appState: AppState
    @Namespace private var glassNamespace

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: Layout.topPadding)

                contactAvatar
                    .padding(.bottom, 24)

                Text(appState.config.contactName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)

                Text(appState.config.contactSubtitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 4)
                    .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 1)

                Spacer()

                actionArea
                    .padding(.horizontal, 28)
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
                    Color(red: 0.09, green: 0.10, blue: 0.16),
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.02, green: 0.03, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.30, green: 0.34, blue: 0.50).opacity(0.45), .clear],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .blendMode(.screen)

            RadialGradient(
                colors: [Color(red: 0.18, green: 0.10, blue: 0.30).opacity(0.30), .clear],
                center: .init(x: 0.5, y: 0.95),
                startRadius: 0,
                endRadius: 380
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
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                .clipShape(Circle())
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 6)
        } else {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))
                    .glassEffect(.regular, in: .circle)
                    .frame(width: Layout.avatarSize, height: Layout.avatarSize)

                Image(systemName: "person.fill")
                    .font(.system(size: 60, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
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
        GlassEffectContainer(spacing: 40) {
            VStack(spacing: 32) {
                HStack(spacing: Layout.secondaryRowSpacing) {
                    CallActionButton(
                        systemImage: "alarm.fill",
                        style: .secondary,
                        size: .small,
                        accessibilityLabel: "Me rappeler",
                        title: "Me rappeler",
                        action: {}
                    )
                    .glassEffectID("remind", in: glassNamespace)

                    CallActionButton(
                        systemImage: "message.fill",
                        style: .secondary,
                        size: .small,
                        accessibilityLabel: "Message",
                        title: "Message",
                        action: {}
                    )
                    .glassEffectID("message", in: glassNamespace)
                }
                .padding(.horizontal, 20)

                HStack(spacing: Layout.primaryRowSpacing) {
                    CallActionButton(
                        systemImage: "phone.down.fill",
                        style: .decline,
                        accessibilityLabel: "Refuser l'appel",
                        title: "Refuser",
                        action: { appState.endCall() }
                    )
                    .glassEffectID("decline", in: glassNamespace)

                    CallActionButton(
                        systemImage: "phone.fill",
                        style: .accept,
                        accessibilityLabel: "Accepter l'appel",
                        title: "Accepter",
                        action: { appState.answerCall() }
                    )
                    .glassEffectID("accept", in: glassNamespace)
                }
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
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    IncomingCallView(appState: AppState.shared)
}
