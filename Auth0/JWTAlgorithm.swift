#if WEB_AUTH_PLATFORM
import Foundation
import JWTDecode
#if SWIFT_PACKAGE
import Auth0ObjectiveC
#endif

enum JWTAlgorithm: String {
    case rs256 = "RS256"

    var shouldVerify: Bool {
        switch self {
        case .rs256: return true
        }
    }

    func verify(_ jwt: JWT, using jwk: JWK) -> Bool {
        let separator = "."
        let parts = jwt.string.components(separatedBy: separator).dropLast().joined(separator: separator)
        guard let data = parts.data(using: .utf8),
            let signature = jwt.signature?.a0_decodeBase64URLSafe(),
            !signature.isEmpty else { return false }
        switch self {
        case .rs256:
            guard let publicKey = jwk.rsaPublicKey, let rsa = A0RSA(key: publicKey) else { return false }
            let sha256 = A0SHA()
            return rsa.verify(sha256.hash(data), signature: signature)
        }
    }
}
#endif
