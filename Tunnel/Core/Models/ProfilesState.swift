import Foundation

/// Persistent storage for call profiles + current selection.
struct ProfilesState: Codable, Equatable {
    var profiles: [CallProfile]
    var activeProfileID: UUID

    init(profiles: [CallProfile], activeProfileID: UUID) {
        self.profiles = profiles
        self.activeProfileID = activeProfileID
    }

    /// Convenience initializer for a single active profile.
    init(single profile: CallProfile) {
        self.profiles = [profile]
        self.activeProfileID = profile.id
    }

    var activeProfileIndex: Int? {
        profiles.firstIndex { $0.id == activeProfileID }
    }

    var activeProfile: CallProfile? {
        guard let idx = activeProfileIndex else { return nil }
        return profiles[idx]
    }

    mutating func setActiveProfile(id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeProfileID = id
    }

    mutating func upsertProfile(_ profile: CallProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
        } else {
            profiles.append(profile)
        }
        if profiles.count == 1 {
            activeProfileID = profiles[0].id
        }
    }
}

