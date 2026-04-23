import OSLog
import PhotosUI
import SwiftUI
import UIKit

/// Native iOS Form layout with contact editing and in-app privacy.
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
                helpSection
                footerSection
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { appState.goHome() }
                        .accessibilityLabel("Fermer les réglages")
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
                            .font(.subheadline.weight(.medium))
                    }
                    .accessibilityLabel(pickerLabel + " du contact")

                    if appState.config.contactImageData != nil {
                        Button("Retirer", role: .destructive) {
                            photoSelection = nil
                            appState.config.contactImageData = nil
                        }
                        .font(.footnote)
                        .accessibilityLabel("Retirer la photo du contact")
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
        .accessibilityHint("Ouvre la page \(label)")
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
