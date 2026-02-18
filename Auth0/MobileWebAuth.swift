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
        // Use custom window if provided
        if let window = presentationWindow {
            return window
        }

        // Find the foreground active scene's key window for multi-window support
        if let windowScene = UIApplication.shared()?.connectedScenes
            .last(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return windowScene.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }

        // Fallback to any key window
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
