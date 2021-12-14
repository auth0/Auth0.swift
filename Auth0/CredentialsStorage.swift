import SimpleKeychain

/// Generic storage API for storing credentials.
public protocol CredentialsStorage {

    /// Retrieve a storage entry.
    ///
    /// - Parameter forKey: The key to get from the store.
    /// - Returns: The stored data.
    func getEntry(forKey: String) -> Data?

    /// Set a storage entry.
    ///
    /// - Parameters:
    ///   - data: The data to be stored.
    ///   - forKey: The key to store it to.
    /// - Returns: If the data was stored.
    func setEntry(_ data: Data, forKey: String) -> Bool

    /// Delete a storage entry.
    ///
    /// - Parameter forKey: The key to delete from the store.
    /// - Returns: If the entry was deleted.
    func deleteEntry(forKey: String) -> Bool

}

extension A0SimpleKeychain: CredentialsStorage {

    /// Retrieve a storage entry.
    ///
    /// - Parameter forKey: The key to get from the Keychain.
    /// - Returns: The stored data.
    public func getEntry(forKey: String) -> Data? {
        return data(forKey: forKey)
    }

    /// Delete a storage entry.
    ///
    /// - Parameter forKey: The key to delete from the Keychain.
    /// - Returns: If the data was stored.
    public func setEntry(_ data: Data, forKey: String) -> Bool {
        return setData(data, forKey: forKey)
    }

}
