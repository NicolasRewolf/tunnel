import OSLog
import PhotosUI
import SwiftUI
import UIKit

struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var photoSelection: PhotosPickerItem?
    private let ringtoneOptions = ["default_ringtone"]
    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "SettingsView")

    private static let avatarPreviewSize: CGFloat = 56
    private static let avatarMaxDimension: CGFloat = 600

    var body: some View {
        NavigationStack {
            Form {
                Section("Identité affichée") {
                    TextField("Nom affiché", text: $appState.config.contactName)
                    TextField("Sous-titre (ex. mobile)", text: $appState.config.contactSubtitle)
                    TextField("Numéro affiché", text: $appState.config.fakePhoneNumber)
                }

                Section("Photo de contact") {
                    HStack(spacing: 14) {
                        avatarPreview
                            .frame(width: Self.avatarPreviewSize, height: Self.avatarPreviewSize)

                        VStack(alignment: .leading, spacing: 6) {
                            PhotosPicker(
                                selection: $photoSelection,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text(appState.config.contactImageData == nil
                                     ? "Choisir une photo"
                                     : "Changer la photo")
                            }

                            if appState.config.contactImageData != nil {
                                Button("Retirer la photo", role: .destructive) {
                                    photoSelection = nil
                                    appState.config.contactImageData = nil
                                }
                            }
                        }
                    }
                }

                Section("Comportement") {
                    Toggle("Répondre avec « Glisser pour répondre »", isOn: $appState.config.useSlideToAnswer)
                }

                Section("Sonnerie") {
                    if ringtoneOptions.count > 1 {
                        Picker("Sonnerie", selection: $appState.config.ringtoneName) {
                            ForEach(ringtoneOptions, id: \.self) { option in
                                Text(localizedRingtoneTitle(for: option)).tag(option)
                            }
                        }
                    } else {
                        LabeledContent("Sonnerie") {
                            Text(localizedRingtoneTitle(for: appState.config.ringtoneName))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Si aucun fichier embarqué n'est trouvé, Tunnel utilise une sonnerie système de secours.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Aucune donnée n'est envoyée : tout reste sur cet iPhone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Aide") {
                    Button("Revoir l'onboarding Back Tap") {
                        appState.openOnboarding()
                    }
                }

                Section {
                    Button("Retour à l'accueil") {
                        appState.goHome()
                    }
                }
            }
            .navigationTitle("Réglages")
            .onChange(of: photoSelection) { _, newValue in
                guard let newValue else { return }
                Task { await loadPickedPhoto(newValue) }
            }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let data = appState.config.contactImageData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else if let imageName = appState.config.contactImageName,
                  let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            Circle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                }
        }
    }

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

    private func localizedRingtoneTitle(for option: String) -> String {
        switch option {
        case "default_ringtone":
            return "Par défaut"
        default:
            return option
        }
    }
}

private extension UIImage {
    /// Returns a copy of the image scaled so its longest side equals `maxDimension`.
    /// Aspect ratio preserved. No-op if the image is already smaller.
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
