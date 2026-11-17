import Foundation
import CommonCrypto

/// Why a PKCE pair could not be created.
enum ChallengeGeneratorError: Error, Equatable {

    /// The system could not provide secure random bytes for the code verifier.
    case randomBytesUnavailable

}

/// The PKCE (RFC 7636) pair of a flow: a code verifier and its S256 code challenge.
struct ChallengeGenerator {
    let verifier: String
    let challenge: String
    let method = "S256"

    /// The pair for a given code verifier.
    init(verifier: String) {
        self.verifier = verifier
        self.challenge = Self.challenge(for: verifier)
    }

    /// The pair for a new random code verifier, made of 32 secure random bytes.
    ///
    /// - Parameter randomBytes: Returns that many secure random bytes, or `nil` when it can't. Defaults to the system's
    ///   generator. It exists so that a test can make it fail.
    /// - Throws: ``ChallengeGeneratorError/randomBytesUnavailable`` when no secure random bytes are available. A fixed or
    ///   empty verifier would be predictable, so none is ever used in its place.
    init(randomBytes: (Int) -> Data? = ChallengeGenerator.systemRandomBytes) throws {
        let count = 32
        guard let bytes = randomBytes(count), bytes.count == count else {
            throw ChallengeGeneratorError.randomBytesUnavailable
        }
        self.init(verifier: bytes.encodeBase64URLSafe())
    }

    /// `count` secure random bytes from the system, or `nil` when it reports a failure.
    static func systemRandomBytes(_ count: Int) -> Data? {
        var data = Data(count: count)
        let status = data.withUnsafeMutableBytes { buffer -> OSStatus in
            guard let base = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, count, base)
        }
        return status == errSecSuccess ? data : nil
    }

    private static func challenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
        }
        return Data(buffer).encodeBase64URLSafe()
    }
}
