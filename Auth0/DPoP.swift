import Foundation
import CryptoKit

protocol DPoPProviding {

    var dpop: DPoP? { get set }

}

extension DPoPProviding {

    mutating func dpop(enabled: Bool) -> Self {
        if enabled {
            self.dpop = DPoP()
        } else {
            self.dpop = nil
        }
        return self
    }

}

struct DPoP {

    private let keyProvider: PoPKeyProvider
    private let maxRetries = 1

    static let nonceRequiredErrorCode = "use_dpop_nonce"
    private static var nonce: String?

    init() {
        self.keyProvider = SecureEnclave.isAvailable ? SecureEnclaveKeyProvider() : KeychainKeyProvider()
    }

    func storeNonce(from response: HTTPURLResponse?) {
        guard let response = response else { return }
        guard let newNonce = response.value(forHTTPHeaderField: "DPoP-Nonce") else { return }

        serialQueue.sync {
            Self.nonce = newNonce
        }
    }

    func shouldRetry(for error: Auth0APIError, retryCount: Int) -> Bool {
        let isDPoPError = error.code == DPoP.nonceRequiredErrorCode
        let isRetryCountExceeded = retryCount >= maxRetries

        return isDPoPError && !isRetryCountExceeded
    }

    func jkt() throws -> String {
        return try serialQueue.sync {
            let publicKey = try keyProvider.privateKey().publicKey
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let jsonData = try encoder.encode(ECPublicKeyJWK(publicKey: publicKey))
            let digest = SHA256.hash(data: jsonData)

            return Data(digest).encodeBase64URLSafe()
        }
    }

    func proof(url: URL, method: String, token: String?) throws -> String {
        try serialQueue.sync {
            let header = try proofHeader()
            let payload = try proofPayload(url: url, method: method, token: token)
            let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
            let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [])
            let jwtParts = "\(headerData.encodeBase64URLSafe()).\(payloadData.encodeBase64URLSafe())"
            let digest = SHA256.hash(data: jwtParts.data(using: .utf8)!)
            let signature = try keyProvider.privateKey().signature(for: Data(digest))

            return "\(jwtParts).\(signature.rawRepresentation.encodeBase64URLSafe())"
        }
    }

    private func proofHeader() throws -> [String: String] {
        let jwk = try keyProvider.privateKey().publicKey.jwkRepresentation
        let jsonJWK = try JSONSerialization.data(withJSONObject: jwk, options: [])

        return [
            "typ": "dpop+jwt",
            "alg": keyProvider.jwsIdentifier,
            "jwk": jsonJWK.encodeBase64URLSafe()
        ]
    }

    private func proofPayload(url: URL, method: String, token: String?) throws -> [String: Any] {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.query = nil
        urlComponents.fragment = nil

        var payload: [String: Any] = [
            "htm": method.uppercased(),
            "htu": urlComponents.url!.absoluteString,
            "jti": UUID().uuidString,
            "iat": Date().timeIntervalSince1970
        ]
        payload["nonce"] = Self.nonce

        if let token = token {
            let digest = SHA256.hash(data: token.data(using: .utf8)!)
            payload["ath"] = Data(digest).encodeBase64URLSafe()
        }

        return payload
    }

    private func extractAccessToken(from request: URLRequest) -> String? {
        guard let authorization = request.value(forHTTPHeaderField: "Authorization"),
              let token = authorization.split(separator: " ").last else { return nil }

        return String(token)
    }

}

// MARK: - Key Management

struct ECPublicKeyJWK: Encodable {

    enum CodingKeys: String, CodingKey {
        // swiftlint:disable:next identifier_name
        case kty, crv, x, y
    }

    let kty = "EC"
    let crv: String
    let x: String // swiftlint:disable:this identifier_name
    let y: String // swiftlint:disable:this identifier_name

    init(publicKey: P256.Signing.PublicKey) {
        self.crv = "P-256"
        let bytes = publicKey.rawRepresentation
        self.x = bytes.prefix(32).encodeBase64URLSafe()
        self.y = bytes.suffix(32).encodeBase64URLSafe()
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

extension P256.Signing.PublicKey {

    var jwkRepresentation: [String: Any] {
        return ECPublicKeyJWK(publicKey: self).toDictionary()
    }

}

protocol SecKeyConvertible: PoPPrivateKey, CustomStringConvertible {

    /// Creates a key from an X9.63 representation.
    init<Bytes>(x963Representation: Bytes) throws where Bytes: ContiguousBytes

    /// An X9.63 representation of the key.
    var x963Representation: Data { get }

}

protocol PoPPrivateKey: Sendable {

    var publicKey: P256.Signing.PublicKey { get }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature

}

extension P256.Signing.PrivateKey: @retroactive CustomStringConvertible {}

extension P256.Signing.PrivateKey: SecKeyConvertible {

    public var description: String {
        return self.x963Representation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }

}

extension SecureEnclave.P256.Signing.PrivateKey: PoPPrivateKey {

    public var description: String {
        return self.dataRepresentation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }

}

protocol PoPKeyProvider {

    func privateKey() throws -> PoPPrivateKey

    var jwsIdentifier: String { get }

}

extension PoPKeyProvider {

    var jwsIdentifier: String {
        return "ES256"
    }

}

// TODO: Improve errors
enum PoPKeyStoreError: Error {

    case storageError(String)
    case retrievalError(String)

}

struct SecureEnclaveKeyProvider: PoPKeyProvider {

    func privateKey() throws -> PoPPrivateKey {
        return try SecureEnclave.P256.Signing.PrivateKey()
    }

}

// TODO: Improve error handling
struct KeychainKeyProvider: PoPKeyProvider {

    let privateKeyIdentifier = "com.auth0.sdk.pop.privateKey"

    // When SecureEnclave is not available, we use a simple keychain store
    func privateKey() throws -> PoPPrivateKey {
        // First, check if the key exists in the keychain
        if let privateKey = try retrieve(forIdentifier: privateKeyIdentifier) {
            return privateKey
        }

        // If not, create a new key and store it in the keychain
        let privateKey = P256.Signing.PrivateKey()
        try store(privateKey, forIdentifier: privateKeyIdentifier)

        return privateKey
    }

    func retrieve(forIdentifier identifier: String) throws -> SecKeyConvertible? {
        // Seek an elliptic-curve key with a given identifier
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationLabel: identifier,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecUseDataProtectionKeychain: true,
            kSecReturnRef: true
        ] as [String: Any]

        // Find and cast the result as a SecKey instance
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else {
            throw PoPKeyStoreError.retrievalError("Keychain retrieval failed with status: \(status)")
        }
        // Ensure the item is a SecKey so the force cast is safe
        guard CFGetTypeID(item) == SecKeyGetTypeID() else {
            throw PoPKeyStoreError.retrievalError("Keychain retrieval returned an unexpected type.")
        }

        // swiftlint:disable:next force_cast
        let secKey = item as! SecKey

        // Convert the SecKey into a CryptoKit key
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(secKey, &error) as Data?, error == nil else {
            throw PoPKeyStoreError.retrievalError("Unable to copy external representation of SecKey: \(String(describing: error))")
        }

        return try P256.Signing.PrivateKey(x963Representation: data)
    }

    func store(_ key: SecKeyConvertible, forIdentifier identifier: String) throws {
        // Describe the key
        let attributes = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                         kSecAttrKeyClass: kSecAttrKeyClassPrivate] as [String: Any]

        // Get a SecKey representation
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(key.x963Representation as CFData,
                                                attributes as CFDictionary,
                                                &error), error == nil else {
            throw PoPKeyStoreError.storageError("Unable to create SecKey representation: \(String(describing: error))")
        }

        // Describe the add operation
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationLabel: identifier,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecUseDataProtectionKeychain: true,
            kSecValueRef: secKey
        ] as [String: Any]

        // Add the key to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PoPKeyStoreError.storageError("Unable to store private key: \(status)")
        }
    }

}
