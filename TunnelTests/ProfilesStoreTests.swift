import XCTest
@testable import Tunnel

final class ProfilesStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: ProfilesStore!

    override func setUp() {
        super.setUp()
        suiteName = "ProfilesStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = ProfilesStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        defaults = nil
        store = nil
        super.tearDown()
    }

    func testFreshInstall_seedsThreeDefaultProfiles() {
        let state = store.loadOrMigrate()
        XCTAssertEqual(state.profiles.count, 3)
        XCTAssertEqual(state.profiles.map(\.contactName), ["Crèche", "Ehpad", "Astreinte"])
        XCTAssertTrue(state.profiles.allSatisfy { $0.contactImageData != nil })
        XCTAssertEqual(state.activeProfileID, state.profiles[0].id)
    }

    func testMigrationFromLegacyConfig() throws {
        let legacy = FakeCallConfig()
        var legacyConfig = legacy
        legacyConfig.contactName = "Ancien contact"
        legacyConfig.contactSubtitle = "Fixe"
        let data = try JSONEncoder().encode(legacyConfig)
        defaults.set(data, forKey: ProfilesStore.StorageKey.legacyConfig)

        let state = store.loadOrMigrate()
        XCTAssertEqual(state.profiles.count, 1)
        XCTAssertEqual(state.profiles[0].contactName, "Ancien contact")
        XCTAssertEqual(state.profiles[0].contactSubtitle, "Fixe")
        XCTAssertNotNil(defaults.data(forKey: ProfilesStore.StorageKey.callProfiles))
    }

    func testProfilesState_deleteLastProfile_createsFallback() {
        var state = ProfilesState(single: CallProfile())
        state.deleteProfile(id: state.profiles[0].id)
        XCTAssertEqual(state.profiles.count, 1)
        XCTAssertEqual(state.profiles[0].contactName, CallProfile.Defaults.contactName)
    }

    func testProfilesState_duplicateProfile_appendsCopyWithoutChangingActive() {
        var original = CallProfile()
        original.contactName = "Original"
        var state = ProfilesState(profiles: [original], activeProfileID: original.id)

        let copyID = state.duplicateProfile(id: original.id)

        XCTAssertEqual(state.profiles.count, 2)
        XCTAssertEqual(copyID, state.profiles[1].id)
        XCTAssertNotEqual(copyID, original.id)
        XCTAssertEqual(state.activeProfileID, original.id)
        XCTAssertEqual(state.profiles[1].contactName, "Original")
        XCTAssertNil(state.duplicateProfile(id: UUID()))
    }

    func testProfilesState_deleteActiveProfile_repointsActiveID() {
        var p1 = CallProfile()
        p1.contactName = "Un"
        var p2 = CallProfile()
        p2.contactName = "Deux"
        var state = ProfilesState(profiles: [p1, p2], activeProfileID: p2.id)
        state.deleteProfile(id: p2.id)
        XCTAssertEqual(state.activeProfileID, p1.id)
    }

    func testRepairInvalidActiveID() throws {
        var p = CallProfile()
        p.contactName = "Seul"
        var state = ProfilesState(profiles: [p], activeProfileID: UUID())
        let data = try JSONEncoder().encode(state)
        defaults.set(data, forKey: ProfilesStore.StorageKey.callProfiles)

        let loaded = store.loadOrMigrate()
        XCTAssertEqual(loaded.activeProfileID, p.id)
    }
}
