import OSLog
import PhotosUI
import SwiftUI
import UIKit

/// Polished settings screen using native iOS Form patterns.
struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var photoSelection: PhotosPickerItem?
    @State private var showPrivacyPolicy = false
    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "SettingsView")

    private static let avatarSize: CGFloat = 60
    private static let avatarMaxDimension: CGFloat = 600

    var body: some View {
        NavigationStack {
            Form {
                // Contact identity
                Section {
                    HStack(spacing: 14) {
                        avatarPreview

                        VStack(alignment: .leading, spacing: 4) {
                            let pickerLabel = appState.config.contactImageData == nil ? "Ajouter une photo" : "Changer la photo"
                            PhotosPicker(
                                selection: $photoSelection,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text(pickerLabel)
                                    .font(.system(size: 15, weight: .medium))
                            }

                            if appState.config.contactImageData != nil {
                                Button("Retirer", role: .destructive) {
                                    photoSelection = nil
                                    appState.config.contactImageData = nil
                                }
                                .font(.system(size: 13))
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)

                    TextField("Nom", text: $appState.config.contactName)
                    TextField("Sous-titre", text: $appState.config.contactSubtitle)
                        .textInputAutocapitalization(.never)
                    TextField("Numéro", text: $appState.config.fakePhoneNumber)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Contact")
                } footer: {
                    Text("Ces informations apparaîtront sur l'écran d'appel.")
                }

                // Behaviour
                Section {
                    Toggle("Glisser pour répondre", isOn: $appState.config.useSlideToAnswer)
                } header: {
                    Text("Apparence de l'appel")
                } footer: {
                    Text("Active pour reproduire l'écran verrouillé d'iPhone.")
                }

                // Help
                Section {
                    Button {
                        appState.openOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            Text("Guide Back Tap")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            Text("Confidentialité")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    VStack(alignment: .center, spacing: 4) {
                        Text("Tunnel")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Simulation locale. Aucune donnée ne quitte cet iPhone.")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        appState.goHome()
                    }
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .onChange(of: photoSelection) { _, newValue in
                guard let newValue else { return }
                Task { await loadPickedPhoto(newValue) }
            }
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarPreview: some View {
        Group {
            if let data = appState.config.contactImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageName = appState.config.contactImageName,
                      let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: Self.avatarSize, height: Self.avatarSize)
        .clipShape(Circle())
    }

    // MARK: - Photo loading

    private func loadPickedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let rawData = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: rawData) else {
                logger.error("Could not decode picked photo into a UIImage.")
                return
            }

            let resized = uiImage.resizedToFit(maxDimension: Self.avatarMaxDimension)
            guard let jpegData = resized.jpegData(compressionQuality: 0.85) else {
                logger.error("Could not encode contact photo to JPEG.")
                return
            }

            await MainActor.run {
                appState.config.contactImageData = jpegData
            }
        } catch {
            logger.error("Failed to load picked photo: \(error.localizedDescription, privacy: .public)")
        }
    }
}

private extension UIImage {
    /// Returns a copy of the image scaled so its longest side equals `maxDimension`.
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview {
    SettingsView(appState: AppState.shared)
}
