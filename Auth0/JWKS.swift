import Foundation

/// The JSON Web Key Set (JWKS) of your Auth0 tenant.
public struct JWKS: Codable {
    /// The keys in the key set.
    public let keys: [JWK]
}

public extension JWKS {

    /// Get a key from the key set by its ID (`kid`).
    func key(id kid: String) -> JWK? {
        return keys.first { $0.keyId == kid }
    }

}

/// Cryptographic public key of your Auth0 tenant.
public struct JWK: Codable {
    /// The type of key.
    public let keyType: String
    /// The unique identifier of the key.
    public let keyId: String?
    /// How the key was meant to be used.
    public let usage: String?
    /// The algorithm of the key.
    public let algorithm: String?
    /// The URL of the x.509 cert.
    public let certUrl: String?
    /// The thumbprint of the x.509 cert (SHA-1 thumbprint).
    public let certThumbprint: String?
    /// The x.509 certificate chain.
    public let certChain: [String]?
    /// The modulus of the key.
    public let rsaModulus: String?
    /// The exponent of the key.
    public let rsaExponent: String?

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
