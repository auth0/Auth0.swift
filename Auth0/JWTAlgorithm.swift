import Foundation
import JWTDecode

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
            var verificationError: Unmanaged<CFError>?
            guard
                SecKeyVerifySignature(
                    jwk.rsaPublicKey!, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, signature as CFData, &verificationError
                )
            else {
                return false
            }
            
            return true
        }
    }
}
