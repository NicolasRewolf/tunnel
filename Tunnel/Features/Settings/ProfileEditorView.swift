import PhotosUI
import SwiftUI
import UIKit

/// Edit a single `CallProfile` (name, subtitle, photo).
struct ProfileEditorView: View {
    @Bindable var appState: AppState
    let profileID: UUID

    @State private var photoSelection: PhotosPickerItem?
    @State private var subtitlePreset: SettingsView.SubtitlePreset = .portable

    private static let avatarSize: CGFloat = 72
    private static let previewAvatarSize: CGFloat = 52
    private static let avatarMaxDimension: CGFloat = 600

    var body: some View {
        Form {
            previewSection

            Section {
                HStack(spacing: 14) {
                    avatarPreview
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
                    ForEach(SettingsView.SubtitlePreset.allCases.filter { $0 != .personnalise }) { preset in
                        Text(preset.label).tag(preset)
                    }
                    Text(SettingsView.SubtitlePreset.personnalise.label).tag(SettingsView.SubtitlePreset.personnalise)
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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            subtitlePreset = SettingsView.SubtitlePreset.matching(profileBinding.wrappedValue.contactSubtitle)
        }
        .onChange(of: profileBinding.wrappedValue.contactSubtitle) { _, new in
            subtitlePreset = SettingsView.SubtitlePreset.matching(new)
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

    private var previewSection: some View {
        Section {
            callPreviewCard
        } header: {
            Label("Aperçu", systemImage: "eye.fill")
        } footer: {
            Text("Visible aussi sur l’appel entrant.")
        }
    }

    private var profileBinding: Binding<CallProfile> {
        Binding(
            get: {
                appState.profilesState.profiles.first(where: { $0.id == profileID }) ?? CallProfile()
            },
            set: { updated in
                appState.addProfile(updated)
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

    private var callPreviewCard: some View {
        let name = profileBinding.wrappedValue.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let caption = profileBinding.wrappedValue.contactSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(alignment: .center, spacing: 14) {
            Group {
                if let data = profileBinding.wrappedValue.contactImageData,
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
    private var avatarPreview: some View {
        Group {
            if let data = profileBinding.wrappedValue.contactImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: Self.avatarSize, height: Self.avatarSize)
        .clipShape(Circle())
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

