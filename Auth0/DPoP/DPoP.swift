import Foundation
import CryptoKit

// MARK: - DPoP Service

/// Utilities for securing requests with DPoP (Demonstrating Proof of Possession) as described in
/// [RFC 9449](https://datatracker.ietf.org/doc/html/rfc9449).
///
/// ## Availability
///
/// This feature is currently available in
/// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
/// Please reach out to Auth0 support to get it enabled for your tenant.
///
/// ## See Also
///
/// - ``DPoPError``
public struct DPoP: Sendable {

    /// The default identifier used to store the key pair on the Keychain, which is the bundle identifier.
    static public let defaultKeychainIdentifier: String = Bundle.main.bundleIdentifier!

    /// The identifier used to store the key pair on the Keychain.
    public let keychainIdentifier: String

    static let nonceRequiredErrorCode = "use_dpop_nonce"
    static private(set) var auth0Nonce: String?
    static private let maxRetries = 1

    private let keyStore: DPoPKeyStore
    private let proofGenerator: DPoPProofGenerator

    init(keychainIdentifier: String = DPoP.defaultKeychainIdentifier) {
        self.keychainIdentifier = keychainIdentifier
        self.keyStore = Self.keyStore(for: keychainIdentifier)
        self.proofGenerator = DPoPProofGenerator(keyStore: keyStore)
    }

    /// Adds the `Authorization` and `DPoP` headers to the provided `URLRequest`. The `Authorization` header is set
    /// using the access token and token type. The `DPoP` header contains the generated DPoP proof.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var request = URLRequest(url: URL(string: "https://example.com/api/endpoint")!)
    /// request.httpMethod = "POST"
    ///
    /// do {
    ///     try DPoP.addHeaders(to: &request,
    ///                         accessToken: credentials.accessToken,
    ///                         tokenType: credentials.tokenType)
    /// } catch {
    ///     print(error)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to which the headers will be added.
    ///   - accessToken: The access token to include in the `Authorization` header. See ``Credentials/accessToken``.
    ///   - tokenType: Either `DPoP` or `Bearer`. See ``Credentials/tokenType``.
    ///   - nonce: Optional nonce value to include in the DPoP proof.
    ///   - keychainIdentifier: The identifier used to store the key pair on the Keychain. Defaults to the bundle identifier.
    /// - Important: The HTTP method is needed for the generation of the DPoP proof, and must already be set on the `URLRequest`.
    /// - Throws: `DPoPError` if the DPoP proof generation fails.
    static public func addHeaders(to request: inout URLRequest,
                                  accessToken: String,
                                  tokenType: String,
                                  nonce: String? = nil,
                                  keychainIdentifier: String = defaultKeychainIdentifier) throws(DPoPError) {
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")

        guard tokenType.caseInsensitiveCompare("dpop") == .orderedSame else { return }
        guard let url = request.url, let method = request.httpMethod else {
            assert(request.url != nil, "The request URL must not be nil.")
            assert(request.httpMethod != nil, "The request HTTP method must not be nil.")
            return
        }

        let proofGenerator = DPoPProofGenerator(keyStore: DPoP.keyStore(for: keychainIdentifier))
        let proof = try proofGenerator.generate(url: url, method: method, nonce: nonce, accessToken: accessToken)

        request.setValue(proof, forHTTPHeaderField: "DPoP")
    }

    /// Clears the key pair stored in the Keychain.
    ///
    /// This method should be called as part of the logout process, along with ``CredentialsManager/clear()``, and
    /// ``WebAuth/clearSession(federated:callback:)-9xcu3`` –when using web-based authentication.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// do {
    ///     try DPoP.clearKeypair()
    /// } catch {
    ///     print(error)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keychainIdentifier: The identifier used to store the key pair on the Keychain. Defaults to the bundle identifier.
    /// - Throws: `DPoPError` if the key pair removal fails.
    static public func clearKeypair(for keychainIdentifier: String = defaultKeychainIdentifier) throws(DPoPError) {
        return try Self.keyStore(for: keychainIdentifier).clear()
    }

    /// Checks the `WWW-Authenticate` header of a failed `HTTPURLResponse` to determine if a nonce must be included in
    /// the DPoP proof. If so, a new nonce value should be present in the `DPoP-Nonce` header of the response. This
    /// nonce should be extracted and used to generate a new DPoP proof. The failed request should then be retried with
    /// the new DPoP proof.
    ///
    /// ## Availability
    ///
    /// This feature is currently available in
    /// [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access).
    /// Please reach out to Auth0 support to get it enabled for your tenant.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// if DPoP.isNonceRequired(by: response),
    ///     let nonce = response.value(forHTTPHeaderField: "DPoP-Nonce") {
    ///     try DPoP.addHeaders(to: &request,
    ///                         accessToken: credentials.accessToken,
    ///                         tokenType: credentials.tokenType,
    ///                         nonce: nonce)
    ///
    ///     // Retry the request with the new DPoP proof that includes the nonce
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - response: The HTTP response to check.
    /// - Returns: `true` if a DPoP nonce is required, `false` otherwise.
    static public func isNonceRequired(by response: HTTPURLResponse) -> Bool {
        return DPoPChallenge(from: response)?.errorCode == nonceRequiredErrorCode
    }

    static func challenge(from response: HTTPURLResponse) -> DPoPChallenge? {
        return DPoPChallenge(from: response)
    }

    static func keyStore(for keychainIdentifier: String,
                         useSecureEnclave: Bool = SecureEnclave.isAvailable) -> DPoPKeyStore {
        return useSecureEnclave ?
        SecureEnclaveKeyStore(keychainService: keychainIdentifier) :
        KeychainKeyStore(keychainTag: keychainIdentifier)
    }

    static func extractNonce(from response: HTTPURLResponse?) -> String? {
        return response?.value(forHTTPHeaderField: "DPoP-Nonce")
    }

    static func storeNonce(from response: HTTPURLResponse?) {
        guard let nonce = extractNonce(from: response) else { return }

        serialQueue.sync {
            auth0Nonce = nonce
        }
    }

    static func shouldRetry(for error: Auth0APIError, retryCount: Int) -> Bool {
        let isDPoPError = error.code == nonceRequiredErrorCode
        let isRetryCountExceeded = retryCount >= maxRetries

        return isDPoPError && !isRetryCountExceeded
    }

    func hasKeypair() throws(DPoPError) -> Bool {
        return try keyStore.hasPrivateKey()
    }

    func shouldGenerateProof(for url: URL, parameters: [String: Any]) throws(DPoPError) -> Bool {
        if url.lastPathComponent == "token",
           let grantType = parameters["grant_type"] as? String,
           grantType != "refresh_token" { return true }

        return try hasKeypair()
    }

    func generateProof(for request: URLRequest) throws(DPoPError) -> String {
        let authorizationHeader = request.value(forHTTPHeaderField: "Authorization")
        let accessToken = authorizationHeader?.components(separatedBy: " ").last

        return try proofGenerator.generate(url: request.url!,
                                           method: request.httpMethod!,
                                           nonce: Self.auth0Nonce,
                                           accessToken: accessToken)
    }

    func jkt() throws(DPoPError) -> String {
        let publicKey = try keyStore.privateKey().publicKey
        return ECPublicKey(from: publicKey).thumbprint()
    }

    // MARK: - Testing Utilities

    static func clearNonce() {
        serialQueue.sync {
            Self.auth0Nonce = nil
        }
    }

    init(keyStore: DPoPKeyStore) {
        self.keychainIdentifier = DPoP.defaultKeychainIdentifier
        self.keyStore = keyStore
        self.proofGenerator = DPoPProofGenerator(keyStore: keyStore)
    }

}
