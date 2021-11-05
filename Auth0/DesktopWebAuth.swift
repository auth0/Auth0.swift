#if os(macOS)
import Cocoa
import AuthenticationServices

/**
 Resumes the current Auth session (if any).

 - parameter urls: urls received by the macOS application in AppDelegate
 - warning: deprecated as the SDK will not support macOS versions older than Catalina
 */
@available(*, deprecated, message: "the SDK will not support macOS versions older than Catalina")
public func resumeAuth(_ urls: [URL]) {
    guard let url = urls.first else { return }
    _ = TransactionStore.shared.resume(url)
}

public extension _ObjectiveOAuth2 {

    /**
     Resumes the current Auth session (if any).

     - parameter urls: urls received by the macOS application in AppDelegate
     - warning: deprecated as the SDK will not support macOS versions older than Catalina
     */
    @available(*, deprecated, message: "the SDK will not support macOS versions older than Catalina")
    @objc(resumeAuthWithURLs:)
    static func resume(_ urls: [URL]) {
        resumeAuth(urls)
    }

}

extension ASTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}

extension ASCallbackTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}
#endif
