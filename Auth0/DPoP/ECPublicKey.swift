import Foundation
import CryptoKit

struct ECPublicKey: Encodable {

    enum CodingKeys: String, CodingKey {
        case type = "kty"
        case curve = "crv"
        case x // swiftlint:disable:this identifier_name
        case y // swiftlint:disable:this identifier_name
    }

    let type = "EC"
    let curve: String
    let x: String // swiftlint:disable:this identifier_name
    let y: String // swiftlint:disable:this identifier_name

    init(from publicKey: P256.Signing.PublicKey) {
        self.curve = "P-256"
        let bytes = publicKey.rawRepresentation
        self.x = bytes.prefix(32).encodeBase64URLSafe()
        self.y = bytes.suffix(32).encodeBase64URLSafe()
    }

    func thumbprint() -> String {
        let json = "{\"\(CodingKeys.curve.rawValue)\":\"\(curve)\",\"\(CodingKeys.type.rawValue)\":\"\(type)\"," +
        "\"\(CodingKeys.x.rawValue)\":\"\(x)\",\"\(CodingKeys.y.rawValue)\":\"\(y)\"}"
        let data = json.data(using: .utf8)!
        return Data(SHA256.hash(data: data)).encodeBase64URLSafe()
    }

    func jwk() -> [String: Any] {
        return [
            CodingKeys.type.rawValue: type,
            CodingKeys.curve.rawValue: curve,
            CodingKeys.x.rawValue: x,
            CodingKeys.y.rawValue: y
        ]
    }

}
