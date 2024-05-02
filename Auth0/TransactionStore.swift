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


    /// Calling store would cancel existing transactions if any, and then would set the supplied transaction as the current one.
    func store(_ transaction: AuthTransaction) {
        self.cancel()
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
