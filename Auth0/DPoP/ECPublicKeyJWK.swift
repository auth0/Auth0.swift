import Foundation
import CryptoKit

struct ECPublicKeyJWK: Encodable {

    enum CodingKeys: String, CodingKey {
        // swiftlint:disable:next identifier_name
        case kty, crv, x, y
    }

    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    let kty = "EC"
    let crv: String
    let x: String // swiftlint:disable:this identifier_name
    let y: String // swiftlint:disable:this identifier_name

    init(from publicKey: P256.Signing.PublicKey) {
        self.crv = "P-256"
        let bytes = publicKey.rawRepresentation
        self.x = bytes.prefix(32).encodeBase64URLSafe()
        self.y = bytes.suffix(32).encodeBase64URLSafe()
    }

    func thumbprint() throws(DPoPError) -> String {
        let jsonData: Data
        do {
            jsonData = try Self.jsonEncoder.encode(self)
        } catch {
            throw DPoPError(code: .other, cause: error)
        }

        return Data(SHA256.hash(data: jsonData)).encodeBase64URLSafe()
    }

    func toDictionary() -> [String: Any] {
        return [
            CodingKeys.kty.rawValue: kty,
            CodingKeys.crv.rawValue: crv,
            CodingKeys.x.rawValue: x,
            CodingKeys.y.rawValue: y
        ]
    }

}
