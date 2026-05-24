import PhotosUI
import SwiftUI
import UIKit

/// Edit a single `CallProfile` (name, subtitle, photo).
struct ProfileEditorView: View {
    @Bindable var appState: AppState
    let profileID: UUID

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if appState.profilesState.profiles.contains(where: { $0.id == profileID }) {
                ProfileEditorForm(appState: appState, profileID: profileID)
            } else {
                ProfileEditorMissingView { dismiss() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileEditorMissingView: View {
    let onDismiss: () -> Void

    var body: some View {
        ContentUnavailableView(
            "Profil introuvable",
            systemImage: "person.crop.circle.badge.exclamationmark",
            description: Text("Ce profil a peut-être été supprimé.")
        )
        .onAppear(perform: onDismiss)
    }
}

private struct ProfileEditorForm: View {
    @Bindable var appState: AppState
    let profileID: UUID

    @State private var photoSelection: PhotosPickerItem?
    @State private var subtitlePreset: ContactSubtitlePreset = .portable

    private static let avatarSize: CGFloat = 72
    private static let avatarMaxDimension: CGFloat = 600

    var body: some View {
        Form {
            Section {
                CallProfilePreviewCard(profile: profileBinding.wrappedValue)
            } header: {
                Label("Aperçu", systemImage: "eye.fill")
            } footer: {
                Text("Visible aussi sur l’appel entrant.")
            }

            ProfileEditorPhotoSection(
                profile: profileBinding,
                photoSelection: $photoSelection,
                onRemovePhoto: removePhoto
            )

            ProfileEditorIdentitySection(
                profile: profileBinding,
                subtitlePreset: $subtitlePreset
            )
        }
        .navigationTitle(profileTitle)
        .onAppear {
            subtitlePreset = ContactSubtitlePreset.matching(profileBinding.wrappedValue.contactSubtitle)
        }
        .onChange(of: profileBinding.wrappedValue.contactSubtitle) { _, new in
            subtitlePreset = ContactSubtitlePreset.matching(new)
        }
        .onChange(of: photoSelection) { _, newValue in
            guard let newValue else { return }
            Task { await loadPickedPhoto(newValue) }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: duplicateProfile) {
                    Image(systemName: "plus.square.on.square")
                }
                .accessibilityLabel("Dupliquer le profil")
            }
        }
    }

    private var profileBinding: Binding<CallProfile> {
        Binding(
            get: {
                appState.profilesState.profiles.first(where: { $0.id == profileID })!
            },
            set: { appState.upsertProfile($0) }
        )
    }

    private var profileTitle: String {
        let t = profileBinding.wrappedValue.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Profil" : t
    }

    private func removePhoto() {
        photoSelection = nil
        profileBinding.wrappedValue.contactImageData = nil
    }

    private func duplicateProfile() {
        appState.duplicateProfile(id: profileID)
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let rawData = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: rawData) else {
                return
            }

            let resized = uiImage.resizedToFit(maxDimension: Self.avatarMaxDimension)
            guard let jpegData = resized.jpegData(compressionQuality: 0.85) else { return }

            await MainActor.run {
                profileBinding.wrappedValue.contactImageData = jpegData
            }
        } catch {
            // Photo is optional; user can retry.
        }
    }
}

private struct ProfileEditorPhotoSection: View {
    @Binding var profile: CallProfile
    @Binding var photoSelection: PhotosPickerItem?
    let onRemovePhoto: () -> Void

    var body: some View {
        Section {
            HStack(spacing: 14) {
                ProfileAvatarView(
                    imageData: profile.contactImageData,
                    size: 72,
                    placeholderIconSize: 28
                )
                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $photoSelection, matching: .images, photoLibrary: .shared()) {
                        Label(
                            profile.contactImageData != nil ? "Remplacer la photo" : "Choisir une photo",
                            systemImage: "photo.on.rectangle.angled"
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderless)

                    if profile.contactImageData != nil {
                        Button("Retirer la photo", role: .destructive, action: onRemovePhoto)
                            .font(.subheadline)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Photo")
        }
    }
}

private struct ProfileEditorIdentitySection: View {
    @Binding var profile: CallProfile
    @Binding var subtitlePreset: ContactSubtitlePreset

    var body: some View {
        Section {
            TextField("", text: $profile.contactName, prompt: Text("ex. Crèche"))
                .textContentType(.name)
                .textInputAutocapitalization(.words)

            Picker("Type de ligne", selection: $subtitlePreset) {
                ForEach(ContactSubtitlePreset.allCases.filter { $0 != .personnalise }) { preset in
                    Text(preset.label).tag(preset)
                }
                Text(ContactSubtitlePreset.personnalise.label).tag(ContactSubtitlePreset.personnalise)
            }
            .onChange(of: subtitlePreset) { _, new in
                if new != .personnalise {
                    profile.contactSubtitle = new.storedValue
                }
            }

            if subtitlePreset == .personnalise {
                TextField("", text: $profile.contactSubtitle, prompt: Text("ex. iPhone, Urgence"))
                    .textInputAutocapitalization(.sentences)
            }
        } header: {
            Text("Qui appelle ?")
        } footer: {
            Text("Nom et légende, comme dans Téléphone.")
        }
    }
}
