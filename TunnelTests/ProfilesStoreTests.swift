import Foundation
import Testing
@testable import Tunnel

struct ProfilesStoreTests {
    @Test func freshInstall_seedsThreeDefaultProfiles() throws {
        let fixture = try ProfilesStoreFixture()
        let state = fixture.store.loadOrMigrate()
        #expect(state.profiles.count == 3)
        #expect(state.profiles.map(\.contactName) == ["Crèche", "Ehpad", "Astreinte"])
        #expect(state.profiles.allSatisfy { $0.contactImageData != nil })
        #expect(state.activeProfileID == state.profiles[0].id)
    }

    @Test func migrationFromLegacyConfig() throws {
        let fixture = try ProfilesStoreFixture()
        var legacyConfig = FakeCallConfig()
        legacyConfig.contactName = "Ancien contact"
        legacyConfig.contactSubtitle = "Fixe"
        let data = try JSONEncoder().encode(legacyConfig)
        fixture.defaults.set(data, forKey: ProfilesStore.StorageKey.legacyConfig)

        let state = fixture.store.loadOrMigrate()
        #expect(state.profiles.count == 1)
        #expect(state.profiles[0].contactName == "Ancien contact")
        #expect(state.profiles[0].contactSubtitle == "Fixe")
        #expect(fixture.defaults.data(forKey: ProfilesStore.StorageKey.callProfiles) != nil)
    }

    @Test func profilesState_deleteLastProfile_createsFallback() {
        var state = ProfilesState(single: CallProfile())
        state.deleteProfile(id: state.profiles[0].id)
        #expect(state.profiles.count == 1)
        #expect(state.profiles[0].contactName == CallProfile.Defaults.contactName)
    }

    @Test func profilesState_duplicateProfile_appendsCopyWithoutChangingActive() {
        var original = CallProfile()
        original.contactName = "Original"
        var state = ProfilesState(profiles: [original], activeProfileID: original.id)

        let copyID = state.duplicateProfile(id: original.id)

        #expect(state.profiles.count == 2)
        #expect(copyID == state.profiles[1].id)
        #expect(copyID != original.id)
        #expect(state.activeProfileID == original.id)
        #expect(state.profiles[1].contactName == "Original")
        #expect(state.duplicateProfile(id: UUID()) == nil)
    }

    @Test func profilesState_deleteActiveProfile_repointsActiveID() {
        var p1 = CallProfile()
        p1.contactName = "Un"
        var p2 = CallProfile()
        p2.contactName = "Deux"
        var state = ProfilesState(profiles: [p1, p2], activeProfileID: p2.id)
        state.deleteProfile(id: p2.id)
        #expect(state.activeProfileID == p1.id)
    }

    @Test func repairInvalidActiveID() throws {
        let fixture = try ProfilesStoreFixture()
        var p = CallProfile()
        p.contactName = "Seul"
        var state = ProfilesState(profiles: [p], activeProfileID: UUID())
        let data = try JSONEncoder().encode(state)
        fixture.defaults.set(data, forKey: ProfilesStore.StorageKey.callProfiles)

        let loaded = fixture.store.loadOrMigrate()
        #expect(loaded.activeProfileID == p.id)
    }
}

/// Isolated `UserDefaults` per test run; cleaned up on deinit.
private final class ProfilesStoreFixture {
    let suiteName: String
    let defaults: UserDefaults
    let store: ProfilesStore

    init() throws {
        suiteName = "ProfilesStoreTests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        store = ProfilesStore(defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
