// swiftlint:disable file_length
import Foundation
import CryptoKit

// MARK: - Enable/Disable DPoP

public protocol DPoPProviding {

    var dpop: DPoP? { get set }

}

public extension DPoPProviding {

    func proofOfPossession(enabled: Bool, keychainTag: String = Bundle.main.bundleIdentifier!) -> Self {
        var instance = self
        if enabled {
            instance.dpop = DPoP(keychainTag: keychainTag)
        } else {
            instance.dpop = nil
        }
        return instance
    }

}

// MARK: - Error Type

public struct DPoPError: Auth0Error, Sendable {

    enum Code: Equatable {
        case secureEnclaveOperationFailed(String)
        case keychainOperationFailed(String)
        case cryptoKitOperationFailed(String)
        case secKeyOperationFailed(String)
        case other
        case unknown(String)
    }

    let code: Code

    init(code: Code, cause: Error? = nil) {
        self.code = code
        self.cause = cause
    }

    /// The underlying `Error` value, if any. Defaults to `nil`.
    public let cause: Error?

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        self.appendCause(to: self.message)
    }

    public static let secureEnclaveOperationFailed: DPoPError = .init(code: .secureEnclaveOperationFailed(""))

    public static let keychainOperationFailed: DPoPError = .init(code: .keychainOperationFailed(""))

    public static let cryptoKitOperationFailed: DPoPError = .init(code: .cryptoKitOperationFailed(""))

    public static let secKeyOperationFailed: DPoPError = .init(code: .secKeyOperationFailed(""))

    /// An unexpected error occurred, and an `Error` value is available.
    /// The underlying `Error` value can be accessed via the ``Auth0Error/cause-9wuyi`` property.
    public static let other: DPoPError = .init(code: .other)

    /// An unexpected error occurred, but an `Error` value is not available.
    /// This error does not include a ``Auth0Error/cause-9wuyi``.
    public static let unknown: DPoPError = .init(code: .unknown(""))

}

extension DPoPError {

    var message: String {
        switch self.code {
        case .secureEnclaveOperationFailed(let message): return message
        case .cryptoKitOperationFailed(let message): return message
        case .secKeyOperationFailed(let message): return message
        case .keychainOperationFailed(let message): return message
        case .other: return "An unexpected error occurred."
        case .unknown(let message): return message
        }
    }

}

extension DPoPError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: DPoPError, rhs: DPoPError) -> Bool {
        return lhs.code == rhs.code && lhs.localizedDescription == rhs.localizedDescription
    }

}

public extension DPoPError {

    /// Matches `DPoPError` values in a switch statement.
    static func ~= (lhs: DPoPError, rhs: DPoPError) -> Bool {
        return lhs.code == rhs.code
    }

    /// Matches `Error` values in a switch statement.
    static func ~= (lhs: DPoPError, rhs: Error) -> Bool {
        guard let rhs = rhs as? DPoPError else { return false }
        return lhs.code == rhs.code
    }

}

// MARK: - DPoP Service

public struct DPoP: Sendable {

    enum Proof {}
    enum JKT {}

    struct Challenge {
        let errorCode: String
        let errorDescription: String?
    }

    private let keyStore: PoPKeyStore
    private let maxRetries = 1

    static let nonceRequiredErrorCode = "use_dpop_nonce"
    private static var nonce: String?

    public init(keychainTag: String = Bundle.main.bundleIdentifier!) {
        let tagData = keychainTag.data(using: .utf8)!
        self.keyStore = SecureEnclave.isAvailable ?
        SecureEnclaveKeyProvider(keychainTag: tagData) :
        KeychainKeyProvider(keychainTag: tagData)
    }

    static func challenge(from response: ResponseValue) -> Challenge? {
        return Challenge(from: response)
    }

    public func generateProof(url: URL, method: String, accessToken: String? = nil) throws(DPoPError) -> String {
        return try withSerialQueueSync {
            return try Proof.generate(using: keyStore,
                                      url: url,
                                      method: method,
                                      nonce: Self.nonce,
                                      accessToken: accessToken)
        }
    }

    public func clearKeypair() throws(DPoPError) {
        return try withSerialQueueSync {
            return try keyStore.clear()
        }
    }

    func jkt() throws(DPoPError) -> String {
        return try withSerialQueueSync {
            return try JKT.generate(using: keyStore)
        }
    }

    func storeNonce(from response: HTTPURLResponse?) {
        guard let response = response else { return }
        guard let newNonce = response.value(forHTTPHeaderField: "DPoP-Nonce") else { return }

        serialQueue.sync {
            Self.nonce = newNonce
        }
    }

    func shouldRetry(for error: Auth0APIError, retryCount: Int) -> Bool {
        let isDPoPError = error.code == Self.nonceRequiredErrorCode
        let isRetryCountExceeded = retryCount >= maxRetries

        return isDPoPError && !isRetryCountExceeded
    }

    private func withSerialQueueSync<T>(_ block: () throws -> T) throws(DPoPError) -> T {
        do {
            return try serialQueue.sync {
                return try block()
            }
        } catch let error as DPoPError {
            throw error
        } catch {
            throw DPoPError(code: .other, cause: error)
        }
    }

}

// MARK: - Proof Generation

extension DPoP.Proof {

    static func generate(using keyStore: PoPKeyStore,
                         url: URL,
                         method: String,
                         nonce: String?,
                         accessToken: String?) throws(DPoPError) -> String {
        let header = try generateHeader(using: keyStore)
        let payload = generatePayload(url: url, method: method, nonce: nonce, accessToken: accessToken)

        let headerData: Data
        let payloadData: Data
        do {
            headerData = try JSONSerialization.data(withJSONObject: header, options: [])
            payloadData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            throw DPoPError(code: .other, cause: error)
        }

        let jwtParts = "\(headerData.encodeBase64URLSafe()).\(payloadData.encodeBase64URLSafe())"
        let digest = SHA256.hash(data: jwtParts.data(using: .utf8)!)
        let privateKey = try keyStore.privateKey()

        do {
            let signature = try privateKey.signature(for: Data(digest))
            return "\(jwtParts).\(signature.rawRepresentation.encodeBase64URLSafe())"
        } catch {
            let message = "Unable to sign the DPoP proof with the private key."
            throw DPoPError(code: .cryptoKitOperationFailed(message), cause: error)
        }
    }

    private static func generateHeader(using keyStore: PoPKeyStore) throws(DPoPError) -> [String: String] {
        let jwk = try keyStore.privateKey().publicKey.jwkRepresentation

        let jsonJWK: Data
        do {
            jsonJWK = try JSONSerialization.data(withJSONObject: jwk, options: [])
        } catch {
            throw DPoPError(code: .other, cause: error)
        }

        return [
            "typ": "dpop+jwt",
            "alg": keyStore.publicKeyJWSIdentifier,
            "jwk": jsonJWK.encodeBase64URLSafe()
        ]
    }

    private static func generatePayload(url: URL,
                                        method: String,
                                        nonce: String?,
                                        accessToken: String?) -> [String: Any] {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.query = nil
        urlComponents.fragment = nil

        var payload: [String: Any] = [
            "htm": method.uppercased(),
            "htu": urlComponents.url!.absoluteString,
            "jti": UUID().uuidString,
            "iat": Date().timeIntervalSince1970
        ]
        payload["nonce"] = nonce

        if let token = accessToken {
            let digest = SHA256.hash(data: token.data(using: .utf8)!)
            payload["ath"] = Data(digest).encodeBase64URLSafe()
        }

        return payload
    }

}

// MARK: - JKT Generation

extension DPoP.JKT {

    static func generate(using keyStore: PoPKeyStore) throws(DPoPError) -> String {
        let publicKey = try keyStore.privateKey().publicKey
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        do {
            let jsonData = try encoder.encode(ECPublicKeyJWK(publicKey: publicKey))
            return Data(SHA256.hash(data: jsonData)).encodeBase64URLSafe()
        } catch {
            throw DPoPError(code: .other, cause: error)
        }
    }

}

// MARK: - Challenge Parsing

extension DPoP.Challenge {

    init?(from response: ResponseValue) {
        guard response.response.statusCode == 401,
              let header = response.response.value(forHTTPHeaderField: "WWW-Authenticate"),
              header.range(of: "DPoP ", options: .caseInsensitive) != nil else { return nil }

        let valuePattern = #"([\x20-\x21\x23-\x5B\x5D-\x7E]+)"#
        let errorCodePattern = #"error=""# + valuePattern + #"""#
        let errorDescriptionPattern = #"error_description=""# + valuePattern + #"""#

        guard let errorCodeRange = header.range(of: errorCodePattern, options: .regularExpression) else {
            return nil
        }

        let errorCode = String(header[errorCodeRange])

        if let errorDescriptionRange = header.range(of: errorDescriptionPattern, options: .regularExpression) {
            self.init(errorCode: errorCode, errorDescription: String(header[errorDescriptionRange]))
        }

        self.init(errorCode: errorCode, errorDescription: nil)
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

// MARK: Secure Enclave Keys
// From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain

protocol GenericPasswordConvertible: PoPPrivateKey, CustomStringConvertible {

    /// Creates a key from a raw representation.
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes

    /// A raw representation of the key.
    var rawRepresentation: Data { get }

}

extension GenericPasswordConvertible {

    public var description: String {
        return self.rawRepresentation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }

}

extension SecureEnclave.P256.Signing.PrivateKey: @retroactive CustomStringConvertible {}

extension SecureEnclave.P256.Signing.PrivateKey: GenericPasswordConvertible {

    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.dataRepresentation)
    }

    var rawRepresentation: Data {
        return dataRepresentation  // Contiguous bytes repackaged as a Data instance.
    }

}

extension ContiguousBytes {

    /// A Data instance created safely from the contiguous bytes without making any copies.
    var dataRepresentation: Data {
        return self.withUnsafeBytes { bytes in
            let cfdata = CFDataCreateWithBytesNoCopy(nil,
                                                     bytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                                     bytes.count,
                                                     kCFAllocatorNull)
            return ((cfdata as NSData?) as Data?) ?? Data()
        }
    }

}

// MARK: Non-Secure Enclave Keys
// From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain

protocol SecKeyConvertible: PoPPrivateKey, CustomStringConvertible {

    /// Creates a key from an X9.63 representation.
    init<Bytes>(x963Representation: Bytes) throws where Bytes: ContiguousBytes

    /// An X9.63 representation of the key.
    var x963Representation: Data { get }

}

extension P256.Signing.PrivateKey: @retroactive CustomStringConvertible {}

// MARK: Private Key Type

protocol PoPPrivateKey: Sendable {

    var publicKey: P256.Signing.PublicKey { get }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature

}

extension SecureEnclave.P256.Signing.PrivateKey: PoPPrivateKey {

    public var description: String {
        return self.dataRepresentation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }

}

extension P256.Signing.PrivateKey: SecKeyConvertible {

    public var description: String {
        return self.x963Representation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }

}

// MARK: Key Providers

protocol PoPKeyStore: Sendable {

    var keychainTag: Data { get }
    var publicKeyJWSIdentifier: String { get }

    func privateKey() throws(DPoPError) -> PoPPrivateKey
    func clear() throws(DPoPError)

}

extension PoPKeyStore {

    var privateKeyIdentifier: String {
        return "com.auth0.sdk.pop.privateKey"
    }

    var publicKeyJWSIdentifier: String {
        return "ES256"
    }

}

// Used when Secure Enclave is available
struct SecureEnclaveKeyProvider: PoPKeyStore {

    let keychainTag: Data

    func privateKey() throws(DPoPError) -> PoPPrivateKey {
        // First, check if the key exists in the keychain
        if let privateKey = try retrieve(forIdentifier: privateKeyIdentifier) { return privateKey }

        // If not, create a new key and store it in the keychain
        let privateKey: SecureEnclave.P256.Signing.PrivateKey
        do {
            privateKey = try SecureEnclave.P256.Signing.PrivateKey()
        } catch {
            let message = "Unable to create a new private key on the Secure Enclave."
            throw DPoPError(code: .secureEnclaveOperationFailed(message), cause: error)
        }

        try store(privateKey, forIdentifier: privateKeyIdentifier)

        return privateKey
    }

    func clear() throws(DPoPError) {
        let query = baseQuery(forIdentifier: privateKeyIdentifier)

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            let message = "Unable to delete the private key representation from the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
    }

    // From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain
    private func store(_ key: GenericPasswordConvertible, forIdentifier identifier: String) throws(DPoPError) {
        // Describe a generic password
        var query = baseQuery(forIdentifier: identifier)
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        query[kSecValueData] = key.rawRepresentation

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            let message = "Unable to store private key representation in the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
    }

    // From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain
    private func retrieve(forIdentifier identifier: String) throws(DPoPError) -> GenericPasswordConvertible? {
        // Seek a generic password with the given account
        var query = baseQuery(forIdentifier: identifier)
        query[kSecReturnData] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else {
            let message = "Unable to retrieve the private key representation from the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
        guard let data = item as? Data else {
            throw DPoPError(code: .unknown("Unable to cast the retrieved private key representation to Data."))
        }

        do {
            return try SecureEnclave.P256.Signing.PrivateKey(rawRepresentation: data)
        } catch {
            let message = "Unable to create a Secure Enclave private key from the retrieved data."
            throw DPoPError(code: .secureEnclaveOperationFailed(message), cause: error)
        }
    }

    private func baseQuery(forIdentifier identifier: String) -> [CFString: Any] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrApplicationTag: keychainTag,
            kSecAttrAccount: identifier,
            kSecUseDataProtectionKeychain: true
        ]
    }

}

// Used when Secure Enclave is not available
struct KeychainKeyProvider: PoPKeyStore {

    let keychainTag: Data

    // When SecureEnclave is not available, we use a simple keychain store
    func privateKey() throws(DPoPError) -> PoPPrivateKey {
        // First, check if the key exists in the keychain
        if let privateKey = try retrieve(forIdentifier: privateKeyIdentifier) { return privateKey }

        // If not, create a new key and store it in the keychain
        let privateKey = P256.Signing.PrivateKey()
        try store(privateKey, forIdentifier: privateKeyIdentifier)

        return privateKey
    }

    func clear() throws(DPoPError) {
        let query = baseQuery(forIdentifier: privateKeyIdentifier)

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            let message = "Unable to delete the private key from the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
    }

    // From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain
    private func retrieve(forIdentifier identifier: String) throws(DPoPError) -> SecKeyConvertible? {
        // Seek an elliptic-curve key with a given identifier
        var query = baseQuery(forIdentifier: privateKeyIdentifier)
        query[kSecAttrKeyType] = kSecAttrKeyTypeECSECPrimeRandom
        query[kSecReturnRef] = true

        // Find and cast the result as a SecKey instance
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else {
            let message = "Unable to retrieve the private key from the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
        // Ensure the item is a SecKey so the force cast is safe
        guard CFGetTypeID(item) == SecKeyGetTypeID() else {
            throw DPoPError(code: .unknown("The item retrieved from the Keychain is not a SecKey."))
        }

        // swiftlint:disable:next force_cast
        let secKey = item as! SecKey

        // Convert the SecKey into a CryptoKit key
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(secKey, &error) as Data?, error == nil else {
            let message = "Unable to copy the external representation of the retrieved SecKey."
            throw DPoPError(code: .secKeyOperationFailed(message), cause: error?.takeUnretainedValue())
        }

        do {
            return try P256.Signing.PrivateKey(x963Representation: data)
        } catch {
            let message = "Unable to create a CryptoKit private key from the retrieved SecKey."
            throw DPoPError(code: .cryptoKitOperationFailed(message), cause: error)
        }
    }

    // From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain
    private func store(_ key: SecKeyConvertible, forIdentifier identifier: String) throws(DPoPError) {
        // Describe the key
        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ] as [String: Any]

        // Get a SecKey representation
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(key.x963Representation as CFData,
                                                attributes as CFDictionary,
                                                &error), error == nil else {
            let message = "Unable to create a SecKey representation from the private key."
            throw DPoPError(code: .secKeyOperationFailed(message), cause: error?.takeUnretainedValue())
        }

        // Describe the add operation
        var query = baseQuery(forIdentifier: privateKeyIdentifier)
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        query[kSecValueRef] = secKey

        // Add the key to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            let message = "Unable to store the private key in the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
    }

    private func baseQuery(forIdentifier identifier: String) -> [CFString: Any] {
        return [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainTag,
            kSecAttrApplicationLabel: identifier,
            kSecUseDataProtectionKeychain: true
        ]
    }

}
