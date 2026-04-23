import Foundation

/// Everything Tunnel needs to draw a convincing incoming call.
/// Stored as JSON in UserDefaults via `Codable`.
struct FakeCallConfig: Codable, Equatable {
    enum Defaults {
        static let contactName = "Contact"
        static let contactSubtitle = "Portable"
        static let fakePhoneNumber = "+33 6 00 00 00 00"
        static let ringtoneName = "default_ringtone"
        static let useSlideToAnswer = false
    }

    var contactName: String = Defaults.contactName
    var contactSubtitle: String = Defaults.contactSubtitle
    var fakePhoneNumber: String = Defaults.fakePhoneNumber
    var ringtoneName: String = Defaults.ringtoneName
    var useSlideToAnswer: Bool = Defaults.useSlideToAnswer

    /// JPEG data of a custom contact photo picked by the user, resized for storage.
    var contactImageData: Data?
}
