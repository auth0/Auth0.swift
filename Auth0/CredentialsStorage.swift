import SimpleKeychain
import Foundation

/// Generic storage API for storing credentials.
public protocol CredentialsStorage {

    /// Retrieves a storage entry.
    ///
    /// - Parameter key: The key to get from the store.
    /// - Returns: The stored data.
    /// - Throws: An error when the get operation fails.
    func getEntry(forKey key: String) throws -> Data

    /// Sets a storage entry.
    ///
    /// - Parameters:
    ///   - data: The data to be stored.
    ///   - key: The key to store it to.
    /// - Throws: An error when the store operation fails.
    func setEntry(_ data: Data, forKey key: String) throws

    /// Deletes a storage entry.
    ///
    /// - Parameter key: The key to delete from the store.
    /// - Throws: An error when the delete operation fails.
    func deleteEntry(forKey key: String) throws

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
    /// - Throws: An error when the get operation fails.
    public func getEntry(forKey key: String) throws -> Data {
        try self.data(forKey: key)
    }

    /// Sets a storage entry.
    ///
    /// - Parameters:
    ///   - data: The data to be stored.
    ///   - key: The key to store it to.
    /// - Throws: An error when the store operation fails.
    public func setEntry(_ data: Data, forKey key: String) throws {
        try self.set(data, forKey: key)
    }

    /// Deletes a storage entry.
    ///
    /// - Parameter key: The key to delete from the Keychain.
    /// - Throws: Error if the delete operation fails.
    public func deleteEntry(forKey key: String) throws {
        try self.deleteItem(forKey: key)
    }

    /// Deletes all storage entries from the Keychain for the service and access group values.
    ///
    /// - Throws: A `SimpleKeychainError` when the operation fails.
    public func deleteAllEntries() throws {
        try self.deleteAll()
    }

}
