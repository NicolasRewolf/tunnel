import Foundation
import OSLog
import UIKit

/// Loads, migrates, and persists `ProfilesState` in `UserDefaults`.
struct ProfilesStore {
    enum StorageKey {
        static let callProfiles = "app.callProfiles"
        /// Legacy single-profile blob (pre–call profiles). Migration only.
        static let legacyConfig = "app.config"
    }

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "rewolf.Tunnel", category: "ProfilesStore")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadOrMigrate() -> ProfilesState {
        if let data = defaults.data(forKey: StorageKey.callProfiles),
           let state = try? JSONDecoder().decode(ProfilesState.self, from: data),
           !state.profiles.isEmpty {
            return repairActiveIDIfNeeded(state)
        }

        if let legacy = loadLegacyConfig() {
            var initial = CallProfile()
            initial.contactName = legacy.contactName
            initial.contactSubtitle = legacy.contactSubtitle
            initial.contactImageData = legacy.contactImageData
            let migrated = ProfilesState(single: initial)
            save(migrated)
            return migrated
        }

        let seeded = defaultStarterProfiles()
        save(seeded)
        return seeded
    }

    func save(_ state: ProfilesState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: StorageKey.callProfiles)
    }

    /// `true` when prior-version data existed before this launch's migration write.
    func hadPriorVersionData() -> Bool {
        defaults.data(forKey: StorageKey.callProfiles) != nil
            || defaults.data(forKey: StorageKey.legacyConfig) != nil
    }

    // MARK: - Private

    private func loadLegacyConfig() -> FakeCallConfig? {
        guard
            let data = defaults.data(forKey: StorageKey.legacyConfig),
            let config = try? JSONDecoder().decode(FakeCallConfig.self, from: data)
        else {
            return nil
        }
        return config
    }

    private func defaultStarterProfiles() -> ProfilesState {
        let starters: [CallProfile] = [
            ProfileAvatarFactory.seededProfile(
                name: "Crèche",
                subtitle: "Portable",
                symbol: "building.2.fill",
                colors: (UIColor.systemTeal, UIColor.systemBlue)
            ),
            ProfileAvatarFactory.seededProfile(
                name: "Ehpad",
                subtitle: "Portable",
                symbol: "cross.case.fill",
                colors: (UIColor.systemPink, UIColor.systemRed)
            ),
            ProfileAvatarFactory.seededProfile(
                name: "Astreinte",
                subtitle: "Portable",
                symbol: "person.badge.clock.fill",
                colors: (UIColor.systemIndigo, UIColor.systemPurple)
            ),
        ]
        return ProfilesState(profiles: starters, activeProfileID: starters[0].id)
    }

    private func repairActiveIDIfNeeded(_ state: ProfilesState) -> ProfilesState {
        guard !state.profiles.isEmpty else { return state }
        if state.profiles.contains(where: { $0.id == state.activeProfileID }) {
            return state
        }
        logger.warning("Repaired invalid activeProfileID — falling back to first profile")
        var repaired = state
        repaired.activeProfileID = state.profiles[0].id
        save(repaired)
        return repaired
    }
}
