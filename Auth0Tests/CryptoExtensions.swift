import Foundation
import Security

@testable import Auth0

extension SecKey {
    func export() -> Data {
        return SecKeyCopyExternalRepresentation(self, nil)! as Data
    }
}
