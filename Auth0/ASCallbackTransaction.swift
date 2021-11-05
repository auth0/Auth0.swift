#if WEB_AUTH_PLATFORM
import AuthenticationServices

final class ASCallbackTransaction: BaseCallbackTransaction {

    init(url: URL, schemeURL: URL, callback: @escaping (Bool) -> Void) {
        super.init(callback: callback)

        let authSession = ASWebAuthenticationSession(url: url,
                                                     callbackURLScheme: schemeURL.scheme) { [weak self] url, _ in
            self?.callback(url != nil)
            TransactionStore.shared.clear()
        }

        if #available(iOS 13.0, *) {
            authSession.presentationContextProvider = self
        }

        self.authSession = authSession
        authSession.start()
    }

}
#endif
