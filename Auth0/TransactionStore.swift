#if WEB_AUTH_PLATFORM
import Foundation

/// Keeps track of the current Auth Transaction.
actor TransactionStore {

    static let shared = TransactionStore()

    private(set) var current: AuthTransaction?

    func resume(_ url: URL) async -> Bool {
        let isResumed = await self.current?.resume(url) ?? false
        await self.clear()
        return isResumed
    }

    func store(_ transaction: AuthTransaction) async {
        self.current = transaction
    }

    func cancel() async {
        await self.current?.cancel()
        await self.clear()
    }

    func clear() async {
        self.current = nil
    }

}
#endif
