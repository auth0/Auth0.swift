#if WEB_AUTH_PLATFORM
import Foundation

/// Keeps track of the current Auth Transaction.
class TransactionStore {

    static let shared = TransactionStore()

    private(set) var current: AuthTransaction?

    func resume(_ url: URL) -> Bool {
        let isResumed = self.current?.resume(url) ?? false
        self.clear()
        return isResumed
    }

    func store(_ transaction: AuthTransaction) {
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
