import Foundation

@testable import Auth0

final class SpyCredentialsStorage: CredentialsStorage {

    var store: [String: Data] = [:]
    var setEntryCallCount = 0
    var deleteEntryCallCount = 0

    func getEntry(forKey key: String) throws -> Data {
        guard let data = store[key] else {
            throw NSError(domain: "SpyCredentialsStorage", code: -1, userInfo: nil)
        }
        return data
    }

    func setEntry(_ data: Data, forKey key: String) throws {
        store[key] = data
        setEntryCallCount += 1
    }

    func deleteEntry(forKey key: String) throws {
        store.removeValue(forKey: key)
        deleteEntryCallCount += 1
    }

    func deleteAllEntries() throws {
        store.removeAll()
    }

}
