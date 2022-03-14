#if os(macOS)
import AppKit
import AuthenticationServices

extension NSApplication {

    static func shared() -> NSApplication? {
        return NSApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? NSApplication
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
