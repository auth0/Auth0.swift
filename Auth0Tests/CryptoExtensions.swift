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

extension JWTAlgorithm {
    func sign(value: Data, key: SecKey = TestKeys.rsaPrivate) -> Data {
        switch self {
        case .rs256:
            let sha256 = A0SHA()
            let rsa = A0RSA(key: key)!
            
            return rsa.sign(sha256.hash(value))
        }
    }
}
