import OSLog
import PhotosUI
import SwiftUI
import UIKit

/// Personnalisation du faux appel : aperçu immédiat, champs étiquetés, raccourcis pour la légende.
struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var photoSelection: PhotosPickerItem?
    @State private var showPrivacyPolicy = false
    @State private var subtitlePreset: SubtitlePreset = .portable

    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "SettingsView")

    private static let avatarSize: CGFloat = 60
    private static let previewAvatarSize: CGFloat = 52
    private static let avatarMaxDimension: CGFloat = 600

    /// Raccourcis + entrée libre pour le sous-titre (fixe, portable…).
    private enum SubtitlePreset: String, CaseIterable, Identifiable {
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

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                appearanceSection
                identitySection
                captionSection
                helpSection
                footerSection
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { appState.goHome() }
                        .accessibilityLabel("Fermer les réglages")
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .onAppear {
                subtitlePreset = SubtitlePreset.matching(appState.config.contactSubtitle)
            }
            .onChange(of: appState.config.contactSubtitle) { _, new in
                subtitlePreset = SubtitlePreset.matching(new)
            }
            .onChange(of: photoSelection) { _, newValue in
                guard let newValue else { return }
                Task { await loadPickedPhoto(newValue) }
            }
        }
    }

    // MARK: - Sections

    private var previewSection: some View {
        Section {
            callPreviewCard
        } header: {
            Label("Aperçu", systemImage: "eye.fill")
        } footer: {
            Text("Ce que tu verras après avoir décroché. Le même nom apparaît aussi sur l’écran d’appel entrant.")
        }
    }

    private var appearanceSection: some View {
        Section {
            HStack(alignment: .center, spacing: 14) {
                avatarPreview(large: true)

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(
                        selection: $photoSelection,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            appState.config.contactImageData == nil ? "Choisir une photo" : "Remplacer la photo",
                            systemImage: "photo.on.rectangle.angled"
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Photo du contact pour l’aperçu et le fond flouté")

                    if appState.config.contactImageData != nil {
                        Button("Retirer la photo", role: .destructive) {
                            photoSelection = nil
                            appState.config.contactImageData = nil
                        }
                        .font(.subheadline)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Photo")
        } footer: {
            Text("Optionnel. Sert pour l’avatar et le flou derrière pendant l’appel.")
        }
    }

    private var identitySection: some View {
        Section {
            TextField("", text: $appState.config.contactName, prompt: Text("ex. Léa Martin"))
                .textContentType(.name)
                .textInputAutocapitalization(.words)
        } header: {
            Text("Nom affiché")
        } footer: {
            Text("C’est le nom que verront les autres s’ils jettent un œil à ton écran — choisis quelque chose de crédible.")
        }
    }

    private var captionSection: some View {
        Section {
            Picker("Type de ligne", selection: $subtitlePreset) {
                ForEach(SubtitlePreset.allCases.filter { $0 != .personnalise }) { preset in
                    Text(preset.label).tag(preset)
                }
                Text(SubtitlePreset.personnalise.label).tag(SubtitlePreset.personnalise)
            }
            .accessibilityLabel("Type de ligne sous le nom")
            .onChange(of: subtitlePreset) { _, new in
                if new != .personnalise {
                    appState.config.contactSubtitle = new.storedValue
                }
            }

            if subtitlePreset == .personnalise {
                TextField("", text: $appState.config.contactSubtitle, prompt: Text("ex. iPhone, Apple Watch"))
                    .textInputAutocapitalization(.sentences)
            }
        } header: {
            Text("Légende sous le nom")
        } footer: {
            Text("Sur iPhone, ce texte ressemble au petit libellé « Fixe » ou « Portable » sous le contact.")
        }
    }

    private var helpSection: some View {
        Section {
            navigationRow(icon: "hand.tap.fill", label: "Déclencher sans ouvrir l’app") {
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
        }
    }

    // MARK: - Preview card

    private var callPreviewCard: some View {
        let name = appState.config.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let caption = appState.config.contactSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(alignment: .center, spacing: 14) {
            Group {
                if let data = appState.config.contactImageData,
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

    @ViewBuilder
    private func avatarPreview(large: Bool) -> some View {
        let size = large ? Self.avatarSize : Self.previewAvatarSize
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
                        .font(.system(size: large ? 26 : 22))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
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
