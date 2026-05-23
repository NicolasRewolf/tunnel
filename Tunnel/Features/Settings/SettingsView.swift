import SwiftUI

/// Réglages : profils, aperçu, son, réactivité, aide.
struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var showPrivacyPolicy = false
    /// Set when the user taps the toolbar "+" — drives the
    /// `.navigationDestination(item:)` push so they land directly in the editor.
    @State private var pendingEditProfileID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                manageProfilesSection
                callPreviewSection
                soundSection
                reactivitySection
                helpSection
                aboutSection
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { appState.goHome() }
                        .accessibilityLabel("Fermer les réglages")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addProfile()
                    } label: {
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

    // MARK: - Profils

    private var manageProfilesSection: some View {
        Section {
            ForEach(appState.profilesState.profiles) { profile in
                HStack(spacing: 12) {
                    Button {
                        appState.setActiveProfile(id: profile.id)
                    } label: {
                        Image(systemName: profile.id == appState.profilesState.activeProfileID
                            ? "checkmark.circle.fill"
                            : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(profile.id == appState.profilesState.activeProfileID
                            ? Color.accentColor
                            : Color.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        profile.id == appState.profilesState.activeProfileID
                            ? "Profil actif"
                            : "Activer ce profil"
                    )

                    NavigationLink {
                        ProfileEditorView(appState: appState, profileID: profile.id)
                    } label: {
                        HStack(spacing: 12) {
                            ProfileAvatarView(imageData: profile.contactImageData, size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profileDisplayName(profile))
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                let subtitle = profile.contactSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        appState.duplicateProfile(id: profile.id)
                    } label: {
                        Label("Dupliquer", systemImage: "plus.square.on.square")
                    }
                    .tint(.indigo)

                    Button(role: .destructive) {
                        appState.deleteProfile(id: profile.id)
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: appState.deleteProfiles)
        } header: {
            Text("Profils")
        } footer: {
            Text("Touche la coche pour le profil déclenché par le bouton d’accueil. Touche le nom pour modifier.")
        }
    }

    private var callPreviewSection: some View {
        Section {
            CallProfilePreviewCard(profile: appState.activeProfile)
        } header: {
            Label("Aperçu", systemImage: "eye.fill")
        } footer: {
            Text("Visible aussi sur l’appel entrant.")
        }
    }

    // MARK: - Son

    private var soundSection: some View {
        Section {
            Text(RingerVolumeGuide.lead)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RingerVolumeNumberedSteps(steps: RingerVolumeGuide.steps)

            Link(destination: RingerVolumeGuide.appleSupportURL) {
                Label("Guide Apple : sonnerie", systemImage: "safari")
            }
            .font(.subheadline)
        } header: {
            Label("Son", systemImage: "speaker.wave.2.fill")
        } footer: {
            Text("Réglage iOS — l’app n’y a pas accès.")
        }
    }

    // MARK: - Réactivité

    private var reactivitySection: some View {
        Section {
            Toggle(isOn: $appState.isReactiveModeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mode réactif")
                        .font(.body)
                    Text(appState.isReactiveModeEnabled
                        ? "Déclenchement instantané, partout"
                        : "Déclenchement quand l’iPhone est réveillé")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Réactivité")
        } footer: {
            Text("Active : Bouton Action et Raccourcis répondent au quart de tour, même quand l’iPhone est verrouillé face contre la table. Coût : environ 5 à 10 % de batterie en plus par jour (audio silencieux maintenu en arrière-plan).\n\nDésactive : il faut réveiller l’iPhone (le retourner face vers toi, ou tapoter discrètement) avant de déclencher. Aucun coût batterie.")
        }
    }

    // MARK: - Aide

    private var helpSection: some View {
        Section {
            navigationRow(icon: "hand.tap.fill", label: "Déclencher sans ouvrir l’app") {
                appState.openOnboarding()
            }
            navigationRow(icon: "arrow.up.right.square", label: "Ouvrir l’app Raccourcis") {
                if let url = URL(string: "shortcuts://") {
                    UIApplication.shared.open(url)
                }
            }
            navigationRow(icon: "lock.shield.fill", label: "Confidentialité") {
                showPrivacyPolicy = true
            }
        } header: {
            Text("Aide")
        } footer: {
            Text(
                Device.hasActionButton
                    ? "Toucher au dos, Bouton Action, Raccourcis : voir l’onboarding."
                    : "Toucher au dos, Raccourcis : voir l’onboarding."
            )
        }
    }

    // MARK: - À propos

    private var aboutSection: some View {
        Section {
            VStack(alignment: .center, spacing: 4) {
                Text("Untunnel")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Simulation locale. Aucune donnée personnelle ne quitte cet iPhone — seul un check de mise à jour quotidien interroge l’App Store.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
        } header: {
            Text("À propos")
        }
    }

    // MARK: - Helpers

    private func navigationRow(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                Text(label)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityLabel(label)
        .accessibilityHint("Ouvre \(label)")
    }

    private func profileDisplayName(_ profile: CallProfile) -> String {
        let t = profile.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Profil" : t
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
