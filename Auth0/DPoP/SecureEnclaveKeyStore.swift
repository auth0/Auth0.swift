import Foundation
import CryptoKit

// Used when Secure Enclave is available
struct SecureEnclaveKeyStore: DPoPKeyStore, @unchecked Sendable {

    let keychainService: String

    var store: StoreFunction = SecItemAdd
    var retrieve: RetrieveFunction = SecItemCopyMatching
    var remove: RemoveFunction = SecItemDelete
    var newPrivateKey = { () throws -> GenericPasswordConvertible in
        return try SecureEnclave.P256.Signing.PrivateKey()
    }

    func hasPrivateKey() throws(DPoPError) -> Bool {
        return try get() != nil
    }

    func privateKey() throws(DPoPError) -> DPoPPrivateKey {
        // First, check if the key exists in the keychain
        if let privateKey = try get() { return privateKey }

        // If not, create a new key and store it in the keychain
        return try Self.withSerialQueueSync {
            let privateKey: GenericPasswordConvertible
            do {
                privateKey = try newPrivateKey()
            } catch {
                let message = "Unable to create a new private key using the Secure Enclave."
                throw DPoPError(code: .secureEnclaveOperationFailed(message), cause: error)
            }

            try store(privateKey)

            return privateKey
        }
    }

    func clear() throws(DPoPError) {
        return try Self.withSerialQueueSync {
            let query = baseQuery()

            let status = remove(query as CFDictionary)
            guard (status == errSecSuccess) || (status == errSecItemNotFound) else {
                let message = "Unable to delete the private key representation from the Keychain. OSStatus: \(status)."
                throw DPoPError(code: .keychainOperationFailed(message))
            }
        }
    }

    // From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain
    private func store(_ key: GenericPasswordConvertible) throws(DPoPError) {
        var query = baseQuery()
        #if !os(macOS)
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #endif
        query[kSecValueData] = key.rawRepresentation

        let status = store(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            let message = "Unable to store private key representation in the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
    }

    // From Apple's sample code at https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain
    private func get() throws(DPoPError) -> GenericPasswordConvertible? {
        var query = baseQuery()
        query[kSecReturnData] = true

        var item: CFTypeRef?
        let status = retrieve(query as CFDictionary, &item)

        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else {
            let message = "Unable to retrieve the private key representation from the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
        guard let data = item as? Data else {
            throw DPoPError(code: .unknown("Unable to cast the retrieved private key representation to a Data value."))
        }

        do {
            return try SecureEnclave.P256.Signing.PrivateKey(rawRepresentation: data)
        } catch {
            let message = "Unable to recreate a Secure Enclave private key from the retrieved data."
            throw DPoPError(code: .secureEnclaveOperationFailed(message), cause: error)
        }
    }

    private func baseQuery() -> [CFString: Any] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: privateKeyIdentifier
        ]
    }

}
