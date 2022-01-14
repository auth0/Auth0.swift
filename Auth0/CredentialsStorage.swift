import SimpleKeychain

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

}

extension A0SimpleKeychain: CredentialsStorage {

    /// Retrieves a storage entry.
    ///
    /// - Parameter key: The key to get from the Keychain.
    /// - Returns: The stored data.
    public func getEntry(forKey key: String) -> Data? {
        return data(forKey: key)
    }

    /// Sets a storage entry.
    ///
    /// - Parameters:
    ///   - data: The data to be stored.
    ///   - key: The key to store it to.
    /// - Returns: If the data was stored.
    public func setEntry(_ data: Data, forKey key: String) -> Bool {
        return setData(data, forKey: key)
    }

}
