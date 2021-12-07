import Foundation

public struct JWKS: Codable {
    let keys: [JWK]
}

public extension JWKS {

    func key(id kid: String) -> JWK? {
        return keys.first { $0.keyId == kid }
    }

}

public struct JWK: Codable {
    let keyType: String
    let keyId: String?
    let usage: String?
    let algorithm: String?
    let certUrl: String?
    let certThumbprint: String?
    let certChain: [String]?
    let rsaModulus: String?
    let rsaExponent: String?

    enum CodingKeys: String, CodingKey {
        case keyType = "kty"
        case keyId = "kid"
        case usage = "use"
        case algorithm = "alg"
        case certUrl = "x5u"
        case certThumbprint = "x5t"
        case certChain = "x5c"
        case rsaModulus = "n"
        case rsaExponent = "e"
    }
}
