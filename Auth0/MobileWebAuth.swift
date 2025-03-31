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
        return UIApplication.shared()?.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
#endif

#if os(visionOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared()?.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return windowScene.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
        return ASPresentationAnchor()
    }
#endif

}
#endif
