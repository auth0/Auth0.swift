import SimpleKeychain
import Foundation

/// Generic storage API for storing credentials.
public protocol CredentialsStorage {

    /// Retrieves a storage entry.
    ///
    /// - Parameter key: The key to get from the store.
    /// - Returns: The stored data.
    func getEntry(forKey key: String) -> Data?

    /// Sets a storage entry.
    ///
    /// - Parameters:
    ///   - data: The data to be stored.
    ///   - key: The key to store it to.
    /// - Returns: If the data was stored.
    func setEntry(_ data: Data, forKey key: String) -> Bool

    /// Deletes a storage entry.
    ///
    /// - Parameter key: The key to delete from the store.
    /// - Returns: If the entry was deleted.
    func deleteEntry(forKey key: String) -> Bool

    /// Deletes all storage entries managed by this ``CredentialsStorage`` instance.
    ///
    /// - Throws: An error when the delete operation fails.
    func deleteAllEntries() throws

}

extension CredentialsStorage {

    /// Default implementation that triggers an assertion failure.
    public func deleteAllEntries() throws {
        assertionFailure("deleteAllEntries() is not implemented. Implement this method in your custom CredentialsStorage.")
    }

}

/// Conformance to ``CredentialsStorage``.
extension SimpleKeychain: CredentialsStorage {

    /// Retrieves a storage entry.
    ///
    /// - Parameter key: The key to get from the Keychain.
    /// - Returns: The stored data.
    public func getEntry(forKey key: String) -> Data? {
        return try? self.data(forKey: key)
    }

    /// Sets a storage entry.
    ///
    /// - Parameters:
    ///   - data: The data to be stored.
    ///   - key: The key to store it to.
    /// - Returns: If the data was stored.
    public func setEntry(_ data: Data, forKey key: String) -> Bool {
        do {
            try self.set(data, forKey: key)
            return true
        } catch {
            return false
        }
    }

    /// Deletes a storage entry.
    ///
    /// - Parameter key: The key to delete from the Keychain.
    /// - Returns: If the data was deleted.
    public func deleteEntry(forKey key: String) -> Bool {
        do {
            try self.deleteItem(forKey: key)
            return true
        } catch {
            return false
        }
    }

    /// Deletes all storage entries from the Keychain for the service and access group values.
    ///
    /// - Throws: A `SimpleKeychainError` when the operation fails.
    public func deleteAllEntries() throws {
        try self.deleteAll()
    }

}
