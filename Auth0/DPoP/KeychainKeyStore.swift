import Foundation
import CryptoKit

// Used when Secure Enclave is not available
struct KeychainKeyStore: DPoPKeyStore {

    let keychainTag: Data

    init(keychainTag: String) {
        self.keychainTag = keychainTag.data(using: .utf8)!
    }

    func hasPrivateKey() throws(DPoPError) -> Bool {
        return try retrieve(forIdentifier: privateKeyIdentifier) != nil
    }

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
        guard (status == errSecSuccess) || (status == errSecItemNotFound) else {
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
