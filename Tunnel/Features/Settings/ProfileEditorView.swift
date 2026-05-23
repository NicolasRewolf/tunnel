import PhotosUI
import SwiftUI
import UIKit

/// Edit a single `CallProfile` (name, subtitle, photo).
struct ProfileEditorView: View {
    @Bindable var appState: AppState
    let profileID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var photoSelection: PhotosPickerItem?
    @State private var subtitlePreset: ContactSubtitlePreset = .portable

    private static let avatarSize: CGFloat = 72
    private static let avatarMaxDimension: CGFloat = 600

    var body: some View {
        Group {
            if appState.profilesState.profiles.contains(where: { $0.id == profileID }) {
                editorForm
            } else {
                ContentUnavailableView(
                    "Profil introuvable",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Ce profil a peut-être été supprimé.")
                )
                .onAppear { dismiss() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var editorForm: some View {
        Form {
            Section {
                CallProfilePreviewCard(profile: profileBinding.wrappedValue)
            } header: {
                Label("Aperçu", systemImage: "eye.fill")
            } footer: {
                Text("Visible aussi sur l’appel entrant.")
            }

            Section {
                HStack(spacing: 14) {
                    ProfileAvatarView(
                        imageData: profileBinding.wrappedValue.contactImageData,
                        size: Self.avatarSize,
                        placeholderIconSize: 28
                    )
                    VStack(alignment: .leading, spacing: 8) {
                        PhotosPicker(selection: $photoSelection, matching: .images, photoLibrary: .shared()) {
                            Label(hasImage ? "Remplacer la photo" : "Choisir une photo", systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderless)

                        if hasImage {
                            Button("Retirer la photo", role: .destructive) {
                                photoSelection = nil
                                profileBinding.wrappedValue.contactImageData = nil
                            }
                            .font(.subheadline)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Photo")
            }

            Section {
                TextField("", text: Binding(
                    get: { profileBinding.wrappedValue.contactName },
                    set: { profileBinding.wrappedValue.contactName = $0 }
                ), prompt: Text("ex. Crèche"))
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
                        profileBinding.wrappedValue.contactSubtitle = new.storedValue
                    }
                }

                if subtitlePreset == .personnalise {
                    TextField("", text: Binding(
                        get: { profileBinding.wrappedValue.contactSubtitle },
                        set: { profileBinding.wrappedValue.contactSubtitle = $0 }
                    ), prompt: Text("ex. iPhone, Urgence"))
                    .textInputAutocapitalization(.sentences)
                }
            } header: {
                Text("Qui appelle ?")
            } footer: {
                Text("Nom et légende, comme dans Téléphone.")
            }
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
                Button {
                    appState.duplicateProfile(id: profileID)
                } label: {
                    Image(systemName: "plus.square.on.square")
                }
                .accessibilityLabel("Dupliquer le profil")
            }
        }
    }

    /// Only used when `profileID` exists in `profilesState` (see `editorForm`).
    private var profileBinding: Binding<CallProfile> {
        Binding(
            get: {
                appState.profilesState.profiles.first(where: { $0.id == profileID })!
            },
            set: { updated in
                appState.upsertProfile(updated)
            }
        )
    }

    private var hasImage: Bool {
        profileBinding.wrappedValue.contactImageData != nil
    }

    private var profileTitle: String {
        let t = profileBinding.wrappedValue.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Profil" : t
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
            // Silent fail: photo is optional, user can retry.
        }
    }
}
