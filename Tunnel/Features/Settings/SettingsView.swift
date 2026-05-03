import SwiftUI

/// Réglages : ordre par importance — faux appel (aperçu, identité, photo), son, aide, à propos.
struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var showPrivacyPolicy = false

    /// Raccourcis + entrée libre pour le sous-titre (fixe, portable…).
    enum SubtitlePreset: String, CaseIterable, Identifiable {
        case portable
        case fixe
        case bureau
        case domicile
        case personnalise

        var id: String { rawValue }

        var label: String {
            switch self {
            case .portable: return "Portable"
            case .fixe: return "Fixe"
            case .bureau: return "Bureau"
            case .domicile: return "Domicile"
            case .personnalise: return "Autre…"
            }
        }

        /// Valeur enregistrée dans `FakeCallConfig.contactSubtitle`.
        var storedValue: String {
            switch self {
            case .portable: return "Portable"
            case .fixe: return "Fixe"
            case .bureau: return "Bureau"
            case .domicile: return "Domicile"
            case .personnalise: return ""
            }
        }

        static func matching(_ string: String) -> SubtitlePreset {
            let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
            for p in SubtitlePreset.allCases where p != .personnalise {
                if p.storedValue.caseInsensitiveCompare(t) == .orderedSame { return p }
            }
            return .personnalise
        }
    }

    private static let previewAvatarSize: CGFloat = 52

    var body: some View {
        NavigationStack {
            Form {
                activeProfileSection
                manageProfilesSection
                callPreviewSection
                // 2 — entendre l’appel
                soundSection
                // 3 — déclencher, vie privée
                helpSection
                // 4 — méta
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
            }
        }
    }

    // MARK: - 1. Aperçu

    private var callPreviewSection: some View {
        Section {
            callPreviewCard
        } header: {
            Label("Aperçu", systemImage: "eye.fill")
        } footer: {
            Text("Visible aussi sur l’appel entrant.")
        }
    }

    // MARK: - 0. Profil actif + gestion

    private var activeProfileID: Binding<UUID> {
        Binding(
            get: { appState.profilesState.activeProfileID },
            set: { newValue in appState.setActiveProfile(id: newValue) }
        )
    }

    private var activeProfileSection: some View {
        Section {
            Picker("Profil actif", selection: activeProfileID) {
                ForEach(appState.profilesState.profiles) { profile in
                    Text(profileDisplayName(profile)).tag(profile.id)
                }
            }
        } header: {
            Text("Profil actif")
        } footer: {
            Text("Le bouton déclenche ce profil.")
        }
    }

    private var manageProfilesSection: some View {
        Section {
            ForEach(appState.profilesState.profiles) { profile in
                NavigationLink {
                    ProfileEditorView(appState: appState, profileID: profile.id)
                } label: {
                    HStack(spacing: 12) {
                        profileAvatar(profile)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profileDisplayName(profile))
                                .font(.body.weight(.medium))
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
                        if profile.id == appState.profilesState.activeProfileID {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        appState.setActiveProfile(id: profile.id)
                    } label: {
                        Label("Activer", systemImage: "checkmark")
                    }
                    .tint(Color.accentColor)
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
            Text("Gérer les profils")
        } footer: {
            Text("Glisse à droite pour activer, à gauche pour dupliquer ou supprimer.")
        }
    }


    // MARK: - 2. Son

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

    // MARK: - 3. Aide

    private var helpSection: some View {
        Section {
            navigationRow(icon: "hand.tap.fill", label: "Déclencher sans ouvrir l’app") {
                appState.openOnboarding()
            }
            navigationRow(icon: "lock.shield.fill", label: "Confidentialité") {
                showPrivacyPolicy = true
            }
        } header: {
            Text("Aide")
        } footer: {
            Text("Toucher au dos, Bouton Action, Raccourcis : voir l’onboarding.")
        }
    }

    // MARK: - 4. À propos

    private var aboutSection: some View {
        Section {
            VStack(alignment: .center, spacing: 4) {
                Text("Untunnel")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Simulation locale. Aucune donnée ne quitte cet iPhone.")
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

    // MARK: - Preview card

    private var callPreviewCard: some View {
        let name = appState.activeProfile.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let caption = appState.activeProfile.contactSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(alignment: .center, spacing: 14) {
            Group {
                if let data = appState.activeProfile.contactImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.12))
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .frame(width: Self.previewAvatarSize, height: Self.previewAvatarSize)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 5) {
                Text(name.isEmpty ? "Nom du contact" : name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(caption.isEmpty ? "Légende (fixe, portable…)" : caption)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)

                Text("00:00")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .monospacedDigit()
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.14, blue: 0.16),
                            Color(red: 0.08, green: 0.08, blue: 0.09),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func profileAvatar(_ profile: CallProfile) -> some View {
        let size: CGFloat = 34
        Group {
            if let data = profile.contactImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func profileDisplayName(_ profile: CallProfile) -> String {
        let t = profile.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Profil" : t
    }

    private func addProfile() {
        var p = CallProfile()
        p.contactName = "Nouveau profil"
        p.contactSubtitle = "Portable"
        appState.addProfile(p)
        appState.setActiveProfile(id: p.id)
    }
}

#Preview {
    SettingsView(appState: AppState.shared)
}
