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

    /// Appends a copy with a new `id`. Does not change the active profile.
    /// Returns the new profile's id, or `nil` if the source id was not found.
    @discardableResult
    mutating func duplicateProfile(id: UUID) -> UUID? {
        guard let existing = profiles.first(where: { $0.id == id }) else { return nil }
        var copy = existing
        copy.id = UUID()
        profiles.append(copy)
        return copy.id
    }

    mutating func deleteProfile(id: UUID) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles.remove(at: idx)
        if profiles.isEmpty {
            let fallback = CallProfile()
            profiles = [fallback]
            activeProfileID = fallback.id
        } else if !profiles.contains(where: { $0.id == activeProfileID }) {
            activeProfileID = profiles[0].id
        }
    }

    mutating func deleteProfiles(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard profiles.indices.contains(index) else { continue }
            profiles.remove(at: index)
        }
        if profiles.isEmpty {
            let fallback = CallProfile()
            profiles = [fallback]
            activeProfileID = fallback.id
        } else if !profiles.contains(where: { $0.id == activeProfileID }) {
            activeProfileID = profiles[0].id
        }
    }
}

