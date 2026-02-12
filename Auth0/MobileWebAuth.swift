#if os(iOS) || os(visionOS)
import UIKit
import AuthenticationServices

extension UIApplication {

    static func shared() -> UIApplication? {
        return UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication
    }

}

extension ASUserAgent: ASWebAuthenticationPresentationContextProviding {

#if os(iOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Use custom window if provided, otherwise fall back to key window
        if let window = presentationWindow {
            return window
        }
        return UIApplication.shared()?.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
#endif

#if os(visionOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Use custom window if provided
        if let window = presentationWindow {
            return window
        }

        // Fall back to key window in foreground-active scene
        if let windowScene = UIApplication.shared()?.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return windowScene.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }

        return ASPresentationAnchor()
    }
#endif

}
#endif
