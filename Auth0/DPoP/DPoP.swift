import Foundation
import CryptoKit

// MARK: - DPoP Service

public struct DPoP: Sendable {

    static public let defaultKeychainTag = Bundle.main.bundleIdentifier!
    static let nonceRequiredErrorCode = "use_dpop_nonce"
    static private(set) var auth0Nonce: String?
    static private let maxRetries = 1

    private let keyStore: DPoPKeyStore
    private let proofGenerator: DPoPProofGenerator

    init(keychainTag: String) {
        self.keyStore = Self.keyStore(for: keychainTag)
        self.proofGenerator = DPoPProofGenerator(keyStore: keyStore)
    }

    static public func addHeaders(to request: inout URLRequest,
                                  accessToken: String,
                                  tokenType: String,
                                  nonce: String? = nil,
                                  keychainTag: String = defaultKeychainTag) throws(DPoPError) {
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")

        guard tokenType.caseInsensitiveCompare("dpop") == .orderedSame else { return }
        guard let url = request.url, let method = request.httpMethod else {
            assert(request.url != nil, "The request URL must not be nil.")
            assert(request.httpMethod != nil, "The request HTTP method must not be nil.")
            return
        }

        let proof = try withSerialQueueSync {
            let proofGenerator = DPoPProofGenerator(keyStore: DPoP.keyStore(for: keychainTag))
            return try proofGenerator.generate(url: url, method: method, nonce: nonce, accessToken: accessToken)
        }

        request.setValue(proof, forHTTPHeaderField: "DPoP")
    }

    static public func clearKeypair(for keychainTag: String = defaultKeychainTag) throws(DPoPError) {
        return try withSerialQueueSync {
            return try Self.keyStore(for: keychainTag).clear()
        }
    }

    static public func isNonceRequired(by response: HTTPURLResponse) -> Bool {
        return DPoPChallenge(from: response)?.errorCode == nonceRequiredErrorCode
    }

    static func challenge(from response: HTTPURLResponse) -> DPoPChallenge? {
        return DPoPChallenge(from: response)
    }

    static func keyStore(for keychainTag: String, useSecureEncave: Bool = SecureEnclave.isAvailable) -> DPoPKeyStore {
        return useSecureEncave ?
        SecureEnclaveKeyStore(keychainService: keychainTag) :
        KeychainKeyStore(keychainTag: keychainTag)
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

    static private func withSerialQueueSync<T>(_ block: () throws -> T) throws(DPoPError) -> T {
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

    func hasKeypair() throws(DPoPError) -> Bool {
        return try Self.withSerialQueueSync {
            return try keyStore.hasPrivateKey()
        }
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

        return try Self.withSerialQueueSync {
            return try proofGenerator.generate(url: request.url!,
                                               method: request.httpMethod!,
                                               nonce: Self.auth0Nonce,
                                               accessToken: accessToken)
        }
    }

    func jkt() throws(DPoPError) -> String {
        return try Self.withSerialQueueSync {
            let publicKey = try keyStore.privateKey().publicKey
            return ECPublicKey(from: publicKey).thumbprint()
        }
    }

    // MARK: - Testing Utilities

    static func resetNonce() {
        serialQueue.sync {
            Self.auth0Nonce = nil
        }
    }

}
