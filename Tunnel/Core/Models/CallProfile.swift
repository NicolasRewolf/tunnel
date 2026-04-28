import Foundation

/// A reusable fake-call identity (name, subtitle, optional avatar).
/// Persisted as JSON in `UserDefaults` via `Codable`.
struct CallProfile: Codable, Equatable, Identifiable {
    enum Defaults {
        static let contactName = "Contact"
        static let contactSubtitle = "Portable"
    }

    var id: UUID = UUID()
    var contactName: String = Defaults.contactName
    var contactSubtitle: String = Defaults.contactSubtitle

    /// JPEG data of a custom contact photo picked by the user, resized for storage.
    var contactImageData: Data?
}

