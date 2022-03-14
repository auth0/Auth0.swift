#if WEB_AUTH_PLATFORM
import Foundation
import CommonCrypto

private func getVerifier() -> String? {
    let data = Data(count: 32)
    var tempData = data
    _ = tempData.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, data.count, $0.baseAddress!)
    }
    return tempData.a0_encodeBase64URLSafe()
}

private func getChallenge(for verifier: String) -> String? {
    guard let data = verifier.data(using: .utf8) else { return nil }
    var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    _ = data.withUnsafeBytes {
        CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
    }
    return Data(buffer).a0_encodeBase64URLSafe()
}

struct ChallengeGenerator {
    let verifier: String
    let challenge: String
    let method = "S256"

    init(verifier: String? = nil) {
        self.verifier = verifier ?? getVerifier()!
        self.challenge = getChallenge(for: self.verifier)!
    }
}
#endif
