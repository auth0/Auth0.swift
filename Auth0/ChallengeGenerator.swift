#if WEB_AUTH_PLATFORM
import Foundation
import CryptoKit

private func getVerifier() -> String {
    let data = Data(count: 32)
    var tempData = data
    _ = tempData.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, data.count, $0.baseAddress!)
    }
    return tempData.encodeBase64URLSafe()
}

private func getChallenge(for verifier: String) -> String {
    let data = verifier.data(using: .utf8)!
    let hash = SHA256.hash(data: data)
    return Data(hash).encodeBase64URLSafe()
}

struct ChallengeGenerator {
    let verifier: String
    let challenge: String
    let method = "S256"

    init(verifier: String? = nil) {
        self.verifier = verifier ?? getVerifier()
        self.challenge = getChallenge(for: self.verifier)
    }
}
#endif
