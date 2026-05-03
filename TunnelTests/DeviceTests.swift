import XCTest
@testable import Tunnel

/// Verifies the hardware-mapping that decides whether to surface
/// Action-Button guidance in the UI. We test against known real model
/// identifiers — getting one wrong would either show unactionable steps
/// to a user without the button, or hide a valid path from someone who has it.
final class DeviceTests: XCTestCase {

    // MARK: - Has Action Button

    func testHasActionButton_iPhone15Pro() {
        XCTAssertTrue(Device.hasActionButton(identifier: "iPhone16,1"))
    }

    func testHasActionButton_iPhone15ProMax() {
        XCTAssertTrue(Device.hasActionButton(identifier: "iPhone16,2"))
    }

    func testHasActionButton_iPhone16Pro() {
        XCTAssertTrue(Device.hasActionButton(identifier: "iPhone17,1"))
    }

    func testHasActionButton_iPhone16Regular() {
        XCTAssertTrue(Device.hasActionButton(identifier: "iPhone17,3"))
    }

    func testHasActionButton_futureModel() {
        // Any iPhone18,X or later (iPhone 17 series, iPhone Air, …)
        XCTAssertTrue(Device.hasActionButton(identifier: "iPhone18,1"))
        XCTAssertTrue(Device.hasActionButton(identifier: "iPhone25,9"))
    }

    // MARK: - No Action Button

    func testNoActionButton_iPhone15() {
        // iPhone 15 (non-Pro) — still has the ring/silent switch.
        XCTAssertFalse(Device.hasActionButton(identifier: "iPhone15,4"))
    }

    func testNoActionButton_iPhone15Plus() {
        XCTAssertFalse(Device.hasActionButton(identifier: "iPhone15,5"))
    }

    func testNoActionButton_iPhone14Pro() {
        XCTAssertFalse(Device.hasActionButton(identifier: "iPhone15,2"))
    }

    func testNoActionButton_iPhone8() {
        XCTAssertFalse(Device.hasActionButton(identifier: "iPhone10,1"))
    }

    // MARK: - Defensive

    func testNoActionButton_iPad() {
        XCTAssertFalse(Device.hasActionButton(identifier: "iPad13,1"))
    }

    func testNoActionButton_malformed() {
        XCTAssertFalse(Device.hasActionButton(identifier: "iPhone"))
        XCTAssertFalse(Device.hasActionButton(identifier: "iPhoneXX,Y"))
        XCTAssertFalse(Device.hasActionButton(identifier: ""))
        XCTAssertFalse(Device.hasActionButton(identifier: "x86_64"))
    }
}
