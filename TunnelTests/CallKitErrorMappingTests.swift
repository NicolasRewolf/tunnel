import CallKit
import XCTest
@testable import Tunnel

/// Vérifie le mapping d’erreurs stables (sans mocker le daemon CallKit).
final class CallKitErrorMappingTests: XCTestCase {
    func testUserFacingMessage_skippedDebounced() {
        let msg = CallKitManager.userFacingMessage(for: CallKitReportSkipped.debounced)
        XCTAssertFalse(msg.isEmpty)
    }

    func testUserFacingMessage_incomingCall_filteredByDND() {
        let err = NSError(
            domain: CXErrorDomainIncomingCall,
            code: CXErrorCodeIncomingCallError.filteredByDoNotDisturb.rawValue
        )
        let msg = CallKitManager.userFacingMessage(for: err)
        XCTAssertTrue(
            msg.contains("Déranger") || msg.contains("réglage"),
            "Message inattendu pour DnD: \(msg)"
        )
    }

    func testUserFacingMessage_incomingCall_unknown() {
        let err = NSError(domain: CXErrorDomainIncomingCall, code: 999_999)
        let msg = CallKitManager.userFacingMessage(for: err)
        XCTAssertEqual(
            msg,
            "Impossible de lancer l'appel. Réessaye dans un instant."
        )
    }
}
