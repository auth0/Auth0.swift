import Foundation
import CryptoKit

public extension Data {
    func a0_encodeBase64URLSafe() -> String? {
        return self
            .base64EncodedString(options: [])
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }
}

func verifier() -> String? {
    let data = Data(count: 32)
    var tempData = data
    let result = tempData.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, data.count, $0.baseAddress!)
    }
    guard result == 0 else { return nil }
    return tempData.a0_encodeBase64URLSafe()
}

func challenge(for verifier: String) -> String? {
    let challenge = verifier
        .data(using: .ascii)
        .map { SHA256.hash(data: $0) }

    guard let challenge = challenge else { return nil }
    return Data(challenge).a0_encodeBase64URLSafe()
}

print(verifier()?.count)
print(challenge(for: verifier()!))
