import CallKit
import Testing
@testable import Tunnel

/// Vérifie le mapping d’erreurs stables (sans mocker le daemon CallKit).
struct CallKitErrorMappingTests {
    @Test func userFacingMessage_skippedDebounced() {
        let msg = CallKitManager.userFacingMessage(for: CallKitReportSkipped.debounced)
        #expect(msg.isEmpty == false)
    }

    @Test func userFacingMessage_incomingCall_filteredByDND() {
        let err = NSError(
            domain: CXErrorDomainIncomingCall,
            code: CXErrorCodeIncomingCallError.filteredByDoNotDisturb.rawValue
        )
        let msg = CallKitManager.userFacingMessage(for: err)
        #expect(msg.contains("Déranger") || msg.contains("réglage"))
    }

    @Test func userFacingMessage_incomingCall_unknown() {
        let err = NSError(domain: CXErrorDomainIncomingCall, code: 999_999)
        let msg = CallKitManager.userFacingMessage(for: err)
        #expect(msg == "Impossible de lancer l'appel. Réessaye dans un instant.")
    }
}
