import Foundation

/// Legacy single-profile blob (pre–call profiles). **Migration only** — new data
/// lives in `ProfilesState` / `app.callProfiles`. Kept so `JSONDecoder` can read
/// old `UserDefaults` keys without data loss.
///
/// Legacy-safe: `JSONDecoder` silently drops keys that aren't declared here,
/// so previous versions' `fakePhoneNumber` in UserDefaults decodes cleanly
/// and is stripped on next save. No explicit migration required.
struct FakeCallConfig: Codable, Equatable {
    enum Defaults {
        static let contactName = "Contact"
        static let contactSubtitle = "Portable"
    }

    var contactName: String = Defaults.contactName
    var contactSubtitle: String = Defaults.contactSubtitle

    /// JPEG data of a custom contact photo picked by the user, resized for storage.
    var contactImageData: Data?
}
