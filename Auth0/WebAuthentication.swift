#if WEB_AUTH_PLATFORM
import Foundation

public struct WebAuthentication {

    private init() {}

    @discardableResult
    public static func resume(with url: URL) -> Bool {
        return TransactionStore.shared.resume(url)
    }

    public static func cancel() {
        TransactionStore.shared.cancel()
    }

}
#endif
