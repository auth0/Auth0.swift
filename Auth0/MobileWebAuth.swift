#if os(iOS)
import UIKit
import AuthenticationServices

public typealias A0URLOptionsKey = UIApplication.OpenURLOptionsKey

/**
 Resumes the current Auth session (if any).

 - parameter url:     url received by the iOS application in AppDelegate
 - parameter options: dictionary with launch options received by the iOS application in AppDelegate

 - returns: if the url was handled by an on going session or not.
 */
@available(*, deprecated, message: "this method is not needed when targeting iOS 11+")
public func resumeAuth(_ url: URL, options: [A0URLOptionsKey: Any] = [:]) -> Bool {
    return TransactionStore.shared.resume(url)
}

@available(iOS 13.0, *)
extension ASTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}

@available(iOS 13.0, *)
extension ASCallbackTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}
#endif
