import SwiftUI

struct HomeView: View {
    @Bindable var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Tunnel")
                        .font(.largeTitle.bold())
                    Text("Sortir d'une conversation en un geste")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .frame(maxWidth: .infinity)

                Spacer()

                VStack(spacing: 12) {
                    Button("Lancer un faux appel") {
                        appState.triggerFakeCallNow()
                    }
                    .buttonStyle(LargeActionButtonStyle())
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 24) {
                        Button("Guide Back Tap") {
                            appState.openOnboarding()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)

                        Spacer()

                        Button("Réglages") {
                            appState.openSettings()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(20)
        }
    }
}

struct LargeActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    HomeView(appState: AppState.shared)
}
