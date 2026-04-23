import OSLog
import PhotosUI
import SwiftUI
import UIKit

/// Native iOS Form layout with contact editing, appearance toggle, and in-app privacy.
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
                contactSection
                appearanceSection
                helpSection
                footerSection
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { appState.goHome() }
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

    // MARK: - Sections

    private var contactSection: some View {
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
    }

    private var appearanceSection: some View {
        Section {
            Toggle("Glisser pour répondre", isOn: $appState.config.useSlideToAnswer)
        } header: {
            Text("Apparence de l'appel")
        } footer: {
            Text("Active pour reproduire l'écran verrouillé d'iPhone.")
        }
    }

    private var helpSection: some View {
        Section {
            navigationRow(icon: "hand.tap.fill", label: "Déclenchement discret") {
                appState.openOnboarding()
            }
            navigationRow(icon: "lock.shield.fill", label: "Confidentialité") {
                showPrivacyPolicy = true
            }
        }
    }

    private var footerSection: some View {
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
    }

    @ViewBuilder
    private var avatarPreview: some View {
        Group {
            if let data = appState.config.contactImageData,
               let uiImage = UIImage(data: data) {
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

#Preview {
    SettingsView(appState: AppState.shared)
}
