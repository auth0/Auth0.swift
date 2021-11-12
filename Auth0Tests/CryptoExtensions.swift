import Foundation
import Security
#if SWIFT_PACKAGE
import Auth0ObjectiveC
#endif

@testable import Auth0

extension SecKey {
    func export() -> Data {
        return SecKeyCopyExternalRepresentation(self, nil)! as Data
    }
}
