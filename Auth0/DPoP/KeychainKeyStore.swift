import Foundation
import CryptoKit

typealias CreateSecKeyFunction = (_ keyData: CFData,
                                  _ attributes: CFDictionary,
                                  _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey?
typealias ExportSecKeyFunction = (_ key: SecKey, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData?

// Used when Secure Enclave is not available
struct KeychainKeyStore: DPoPKeyStore, @unchecked Sendable {

    let keychainTag: String

    var store: StoreFunction = SecItemAdd
    var retrieve: RetrieveFunction = SecItemCopyMatching
    var remove: RemoveFunction = SecItemDelete
    var createSecKey: CreateSecKeyFunction = SecKeyCreateWithData
    var exportSecKey: ExportSecKeyFunction = SecKeyCopyExternalRepresentation
    var newPrivateKey = { () -> SecKeyConvertible in
        return P256.Signing.PrivateKey()
    }

    init(keychainTag: String) {
        self.keychainTag = keychainTag
    }

    func hasPrivateKey() throws(DPoPError) -> Bool {
        return try get() != nil
    }

    // When SecureEnclave is not available, we use a simple keychain store
    func privateKey() throws(DPoPError) -> DPoPPrivateKey {
        // First, check if the key exists in the keychain
        if let privateKey = try get() { return privateKey }

        return try Self.withSerialQueueSync {
            // If not, create a new key and store it in the keychain
            let privateKey = newPrivateKey()
            try store(privateKey)

            return privateKey
        }
    }

    func clear() throws(DPoPError) {
        return try Self.withSerialQueueSync {
            let status = remove(baseQuery() as CFDictionary)

            guard (status == errSecSuccess) || (status == errSecItemNotFound) else {
                let message = "Unable to delete the private key from the Keychain. OSStatus: \(status)."
                throw DPoPError(code: .keychainOperationFailed(message))
            }
        }
    }

    private func get() throws(DPoPError) -> SecKeyConvertible? {
        // Seek an elliptic-curve key
        var query = baseQuery()
        query[kSecAttrKeyType] = kSecAttrKeyTypeECSECPrimeRandom
        query[kSecReturnRef] = true

        // Find and cast the result as a SecKey instance
        var item: CFTypeRef?
        let status = retrieve(query as CFDictionary, &item)

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
        guard let data = exportSecKey(secKey, &error) as Data?, error == nil else {
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

    private func store(_ key: SecKeyConvertible) throws(DPoPError) {
        // Describe the key
        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ] as [String: Any]

        // Get a SecKey representation
        var error: Unmanaged<CFError>?
        guard let secKey = createSecKey(key.x963Representation as CFData,
                                        attributes as CFDictionary,
                                        &error), error == nil else {
            let message = "Unable to create a SecKey representation from the private key."
            throw DPoPError(code: .secKeyOperationFailed(message), cause: error?.takeUnretainedValue())
        }

        // Describe the add operation
        var query = baseQuery()
        #if !os(macOS)
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #endif
        query[kSecValueRef] = secKey

        // Add the key to the keychain
        let status = store(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            let message = "Unable to store the private key in the Keychain. OSStatus: \(status)."
            throw DPoPError(code: .keychainOperationFailed(message))
        }
    }

    private func baseQuery() -> [CFString: Any] {
        return [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainTag.data(using: .utf8)!,
            kSecAttrApplicationLabel: privateKeyIdentifier
        ]
    }

}
