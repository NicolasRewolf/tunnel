import SwiftUI

/// Réglages : profils, aperçu, son, réactivité, aide.
struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var showPrivacyPolicy = false
    @State private var pendingEditProfileID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                SettingsProfilesSection(
                    profiles: appState.profilesState.profiles,
                    activeProfileID: appState.profilesState.activeProfileID,
                    appState: appState,
                    onDelete: appState.deleteProfiles
                )
                SettingsCallPreviewSection(profile: appState.activeProfile)
                SettingsSoundSection()
                SettingsReactivitySection(isReactiveModeEnabled: $appState.isReactiveModeEnabled)
                SettingsHelpSection(
                    hasActionButton: Device.hasActionButton,
                    onOpenOnboarding: { appState.openOnboarding() },
                    onOpenPrivacy: { showPrivacyPolicy = true }
                )
                SettingsAboutSection()
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer", action: closeSettings)
                        .accessibilityLabel("Fermer les réglages")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addProfile) {
                        Label("Ajouter", systemImage: "person.crop.circle.badge.plus")
                    }
                    .accessibilityLabel("Ajouter un profil")
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(item: $pendingEditProfileID) { profileID in
                ProfileEditorView(appState: appState, profileID: profileID)
            }
        }
    }

    private func closeSettings() {
        appState.goHome()
    }

    private func addProfile() {
        var profile = CallProfile()
        profile.contactName = "Nouveau profil"
        profile.contactSubtitle = "Portable"
        appState.upsertProfile(profile)
        appState.setActiveProfile(id: profile.id)
        pendingEditProfileID = profile.id
    }
}

#Preview {
    SettingsView(appState: AppState.shared)
}
