import Testing
@testable import Tunnel

/// Verifies the hardware-mapping that decides whether to surface
/// Action-Button guidance in the UI.
struct DeviceTests {
    @Test(arguments: [
        ("iPhone16,1", true),
        ("iPhone16,2", true),
        ("iPhone17,1", true),
        ("iPhone17,3", true),
        ("iPhone18,1", true),
        ("iPhone25,9", true),
    ])
    func hasActionButton(identifier: String, expected: Bool) {
        #expect(Device.hasActionButton(identifier: identifier) == expected)
    }

    @Test(arguments: [
        ("iPhone15,4", false),
        ("iPhone15,5", false),
        ("iPhone15,2", false),
        ("iPhone10,1", false),
        ("iPad13,1", false),
        ("iPhone", false),
        ("iPhoneXX,Y", false),
        ("", false),
        ("x86_64", false),
    ])
    func noActionButton(identifier: String, expected: Bool) {
        #expect(Device.hasActionButton(identifier: identifier) == expected)
    }
}
