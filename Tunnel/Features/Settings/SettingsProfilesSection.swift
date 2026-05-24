import SwiftUI

struct SettingsProfilesSection: View {
    let profiles: [CallProfile]
    let activeProfileID: UUID
    @Bindable var appState: AppState
    let onDelete: (IndexSet) -> Void

    var body: some View {
        Section {
            ForEach(profiles) { profile in
                SettingsProfileRow(
                    profile: profile,
                    isActive: profile.id == activeProfileID,
                    appState: appState
                )
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
            .onDelete(perform: onDelete)
        } header: {
            Text("Profils")
        } footer: {
            Text("Touche la coche pour le profil déclenché par le bouton d’accueil. Touche le nom pour modifier.")
        }
    }
}

private struct SettingsProfileRow: View {
    let profile: CallProfile
    let isActive: Bool
    @Bindable var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Button {
                appState.setActiveProfile(id: profile.id)
            } label: {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isActive ? "Profil actif" : "Activer ce profil")

            NavigationLink {
                ProfileEditorView(appState: appState, profileID: profile.id)
            } label: {
                HStack(spacing: 12) {
                    ProfileAvatarView(imageData: profile.contactImageData, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(SettingsProfileRow.displayName(profile))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if let subtitle = SettingsProfileRow.subtitleLine(profile) {
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
    }

    static func displayName(_ profile: CallProfile) -> String {
        let t = profile.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Profil" : t
    }

    static func subtitleLine(_ profile: CallProfile) -> String? {
        let subtitle = profile.contactSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return subtitle.isEmpty ? nil : subtitle
    }
}
