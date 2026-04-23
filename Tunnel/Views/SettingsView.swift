import OSLog
import PhotosUI
import SwiftUI
import UIKit

/// Native iOS Form layout with contact editing, appearance toggle, and in-app privacy.
struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var photoSelection: PhotosPickerItem?
    @State private var showPrivacyPolicy = false
    @State private var previewPlayer = RingtonePreviewPlayer()
    @State private var isPreviewing = false
    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "SettingsView")

    private static let avatarSize: CGFloat = 60
    private static let avatarMaxDimension: CGFloat = 600

    var body: some View {
        NavigationStack {
            Form {
                contactSection
                appearanceSection
                ringtoneSection
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
            .onChange(of: appState.config.ringtoneName) { _, newValue in
                previewPlayer.stop()
                isPreviewing = false
                previewPlayer.currentRingtoneName = newValue
            }
            .onDisappear {
                previewPlayer.stop()
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

    private var ringtoneSection: some View {
        Section {
            Picker("Sonnerie", selection: $appState.config.ringtoneName) {
                ForEach(Self.availableRingtoneNames, id: \.self) { ringtoneName in
                    Text(Self.displayName(for: ringtoneName)).tag(ringtoneName)
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if isPreviewing {
                    previewPlayer.stop()
                    isPreviewing = false
                } else {
                    previewPlayer.play(ringtoneName: appState.config.ringtoneName) {
                        Task { @MainActor in
                            isPreviewing = false
                        }
                        logger.debug("Ringtone preview ended.")
                    }
                    isPreviewing = true
                }
            } label: {
                Label(isPreviewing ? "Stop" : "Écouter", systemImage: isPreviewing ? "stop.fill" : "play.fill")
            }
            .disabled(Self.availableRingtoneNames.isEmpty)
        } header: {
            Text("Sonnerie")
        } footer: {
            Text("Choisis la sonnerie utilisée pour l'appel entrant.")
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

    private static var availableRingtoneNames: [String] {
        let exts = ["caf", "m4a", "wav", "mp3"]
        var names: Set<String> = []

        for ext in exts {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Sounds") ?? []
            for url in urls {
                names.insert(url.deletingPathExtension().lastPathComponent)
            }
        }

        let sorted = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        if sorted.contains("default_ringtone") {
            return ["default_ringtone"] + sorted.filter { $0 != "default_ringtone" }
        }
        return sorted
    }

    private static func displayName(for ringtoneName: String) -> String {
        if ringtoneName == "default_ringtone" { return "Par défaut" }
        var name = ringtoneName
        name = name.replacingOccurrences(of: "Tunnel - Ring Tone ", with: "")
        name = name.replacingOccurrences(of: "_", with: " ")
        name = name.replacingOccurrences(of: "-", with: "–")
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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

#if canImport(AVFoundation)
import AVFoundation

@MainActor
private final class RingtonePreviewPlayer: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var completion: (() -> Void)?
    var currentRingtoneName: String = "default_ringtone"

    func play(ringtoneName: String, completion: @escaping () -> Void) {
        stop()
        self.completion = completion

        let exts = ["caf", "m4a", "wav", "mp3"]
        let url = exts.compactMap { Bundle.main.url(forResource: ringtoneName, withExtension: $0, subdirectory: "Sounds") }.first
        guard let url else {
            completion()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.numberOfLoops = 0
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            completion()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        completion = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {}
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let completion = completion
        stop()
        completion?()
    }
}
#endif

#Preview {
    SettingsView(appState: AppState.shared)
}
