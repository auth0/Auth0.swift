#if WEB_AUTH_PLATFORM
import Foundation

/// Keeps track of the current Auth Transaction.
class TransactionStore {

    static let shared = TransactionStore()

    private(set) var current: AuthTransaction?

    func resume(_ url: URL) -> Bool {
        let resumed = self.current?.resume(url) ?? false
        if resumed {
            self.clear()
        }
        return resumed
    }

    func store(_ transaction: AuthTransaction) {
        self.current?.cancel()
        self.current = transaction
    }

    func cancel() {
        self.current?.cancel()
        self.clear()
    }

    func clear() {
        self.current = nil
    }

}
#endif
