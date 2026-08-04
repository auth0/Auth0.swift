#if os(macOS)
import AppKit
import AuthenticationServices

extension NSApplication {

    static func shared() -> NSApplication? {
        return NSApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? NSApplication
    }

}

extension ASUserAgent: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Use custom window if provided, otherwise fall back to key window
        if let window = presentationWindow {
            return window
        }
        return NSApplication.shared()?.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }

}
#endif
