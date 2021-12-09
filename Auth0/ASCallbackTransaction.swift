#if WEB_AUTH_PLATFORM
import AuthenticationServices

final class ASCallbackTransaction: BaseCallbackTransaction {

    init(url: URL, schemeURL: URL, callback: @escaping (WebAuthResult<Void>) -> Void) {
        super.init(callback: callback)

        let authSession = ASWebAuthenticationSession(url: url,
                                                     callbackURLScheme: schemeURL.scheme) { [weak self] in
            guard $0 != nil, $1 == nil else {
                if let authError = $1, case ASWebAuthenticationSessionError.canceledLogin = authError {
                    self?.callback(.failure(WebAuthError(code: .userCancelled)))
                } else {
                    self?.callback(.failure(WebAuthError(code: .unknown("ASWebAuthenticationSession failed"))))
                }
                return TransactionStore.shared.clear()
            }
            self?.callback(.success(()))
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
