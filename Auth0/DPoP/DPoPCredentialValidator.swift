import Foundation
import SimpleKeychain

struct DPoPCredentialValidator: Sendable {

    private let authentication: Authentication
    private let sendableStorage: SendableBox<CredentialsStorage>
    private let thumbprintKey: String
    private let credentialsKey: String

    private var storage: CredentialsStorage { sendableStorage.value }

    init(authentication: Authentication,
         storage: CredentialsStorage,
         credentialsKey: String,
         thumbprintKey: String) {
        self.authentication = authentication
        self.sendableStorage = SendableBox(value: storage)
        self.credentialsKey = credentialsKey
        self.thumbprintKey = thumbprintKey
    }

    /// Validates DPoP state for the given credentials before attempting renewal.
    ///
    /// - If the credentials are not DPoP-bound (no DPoP token type and no stored thumbprint), returns immediately.
    /// - If DPoP-bound but the `Authentication` client has no DPoP configuration, throws `.dpopNotConfigured`.
    /// - If the key pair is missing, clears credentials and throws `.dpopKeyMissing`.
    /// - If the stored thumbprint doesn't match the current key, clears credentials and throws `.dpopKeyMismatch`.
    /// - If no thumbprint is stored yet, persists the current one for future validation.
    func validate(for credentials: Credentials) throws {
        let storedThumbprint = storedThumbprintValue()
        let isDPoPBound = credentials.tokenType.caseInsensitiveCompare("DPoP") == .orderedSame
            || storedThumbprint != nil

        guard isDPoPBound else { return }

        guard let dpop = authentication.dpop else {
            throw CredentialsManagerError.dpopNotConfigured
        }

        let hasKeyPair = try? dpop.hasKeypair()
        guard hasKeyPair == true else {
            try clearAll()
            throw CredentialsManagerError.dpopKeyMissing
        }

        let currentThumbprint = try dpop.jkt()
        if let stored = storedThumbprint {
            guard stored == currentThumbprint else {
                try clearAll()
                throw CredentialsManagerError.dpopKeyMismatch
            }
        } else {
            try storage.setEntry(Data(currentThumbprint.utf8), forKey: thumbprintKey)
        }
    }

    /// Saves the DPoP thumbprint alongside newly stored credentials.
    ///
    /// Called by `CredentialsManager.store(credentials:)`. Clears the thumbprint entry when
    /// the new credentials are not DPoP-bound and no DPoP client is configured.
    func saveThumbprint(for credentials: Credentials) {
        let isDPoP = credentials.tokenType.caseInsensitiveCompare("DPoP") == .orderedSame
            || authentication.dpop != nil
        guard isDPoP, let dpop = authentication.dpop, let thumbprint = try? dpop.jkt() else {
            try? storage.deleteEntry(forKey: thumbprintKey)
            return
        }
        try? storage.setEntry(Data(thumbprint.utf8), forKey: thumbprintKey)
    }

    /// Clears the stored DPoP thumbprint.
    func clearThumbprint() {
        try? storage.deleteEntry(forKey: thumbprintKey)
    }

    // MARK: - Private

    private func clearAll() throws {
        try storage.deleteEntry(forKey: credentialsKey)
        try? storage.deleteEntry(forKey: thumbprintKey)
    }

    private func storedThumbprintValue() -> String? {
        let data = try? storage.getEntry(forKey: thumbprintKey)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }
}
