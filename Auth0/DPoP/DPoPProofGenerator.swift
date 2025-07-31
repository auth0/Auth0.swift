import Foundation
import CryptoKit

struct DPoPProofGenerator {

    private let keyStore: DPoPKeyStore

    init(keyStore: DPoPKeyStore) {
        self.keyStore = keyStore
    }

    func generate(url: URL, method: String, nonce: String?, accessToken: String?) throws(DPoPError) -> String {
        let privateKey = try keyStore.privateKey()
        let header = generateHeader(publicKey: privateKey.publicKey)
        let payload = generatePayload(url: url, method: method, nonce: nonce, accessToken: accessToken)

        let headerData: Data
        let payloadData: Data
        do {
            headerData = try JSONSerialization.data(withJSONObject: header, options: [])
            payloadData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            throw DPoPError(code: .other, cause: error)
        }

        let signableParts = "\(headerData.encodeBase64URLSafe()).\(payloadData.encodeBase64URLSafe())"

        do {
            let signature = try privateKey.signature(for: signableParts.data(using: .utf8)!)
            return "\(signableParts).\(signature.dataRepresentation.encodeBase64URLSafe())"
        } catch {
            let message = "Unable to sign the DPoP proof with the private key."
            throw DPoPError(code: .cryptoKitOperationFailed(message), cause: error)
        }
    }

    private func generateHeader(publicKey: P256.Signing.PublicKey) -> [String: Any] {
        return [
            "typ": "dpop+jwt",
            "alg": publicKey.jwsIdentifier,
            "jwk": ECPublicKey(from: publicKey).jwk()
        ]
    }

    private func generatePayload(url: URL, method: String, nonce: String?, accessToken: String?) -> [String: Any] {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.query = nil
        urlComponents.fragment = nil

        var payload: [String: Any] = [
            "htm": method.uppercased(),
            "htu": urlComponents.url!.absoluteString,
            "jti": UUID().uuidString,
            "iat": Int(Date().timeIntervalSince1970)
        ]
        payload["nonce"] = nonce

        if let token = accessToken {
            let digest = SHA256.hash(data: token.data(using: .utf8)!)
            payload["ath"] = Data(digest).encodeBase64URLSafe()
        }

        return payload
    }

}
