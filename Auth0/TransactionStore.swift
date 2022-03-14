#if WEB_AUTH_PLATFORM
import Foundation

/// Keeps track of the current Auth Transaction.
class TransactionStore {

    static let shared = TransactionStore()

    private(set) var current: AuthTransaction?

    func resume(_ url: URL) -> Bool {
        let resumed = self.current?.resume(url) ?? false
        if resumed {
            self.current = nil
        }
        return resumed
    }

    func store(_ transaction: AuthTransaction) {
        self.current?.cancel()
        self.current = transaction
    }

    func cancel(_ transaction: AuthTransaction) {
        transaction.cancel()
        if self.current?.state == transaction.state {
            self.current = nil
        }
    }

    func clear() {
        self.current = nil
    }

}
#endif
