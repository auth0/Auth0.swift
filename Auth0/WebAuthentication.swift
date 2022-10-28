#if WEB_AUTH_PLATFORM
import Foundation

/// Utility methods needed when using a custom Web Auth provider.
///
/// ## See Also
///
/// - ``WebAuth/provider(_:)``
/// - ``WebAuthUserAgent``
public struct WebAuthentication {

    private init() {}

    /// Resumes the web-based operation when the external user agent redirects back to the app using a URL with a
    /// custom scheme.
    ///
    /// ## Usage
    ///
    /// ### For UIKit app lifecycle
    ///
    /// In your `AppDelegate.swift`:
    ///
    /// ```swift
    /// func application(_ app: UIApplication,
    ///                  open url: URL,
    ///                  options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    ///     return WebAuthentication.resume(with: url)
    /// }
    /// ```
    ///
    /// ### For UIKit app lifecycle with Scenes
    ///
    /// In your `SceneDelegate.swift`:
    ///
    /// ```swift
    /// func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    ///     guard let url = URLContexts.first?.url else { return }
    ///     WebAuthentication.resume(with: url)
    /// }
    /// ```
    ///
    /// ### For SwiftUI app lifecycle
    ///
    /// ```swift
    /// SomeView()
    ///     .onOpenURL { url in
    ///         WebAuthentication.resume(with: url)
    ///     }
    /// ```
    ///
    /// - Parameter url: The URL sent by the external user agent that contains the result of the web-based operation.
    /// - Returns: If the URL was expected and properly formatted.
    @discardableResult
    public static func resume(with url: URL) -> Bool {
        return TransactionStore.shared.resume(url)
    }

    /// Terminates the ongoing web-based operation and reports back that it was cancelled.
    /// You need to call this method within your custom Web Auth provider implementation whenever the operation is
    /// cancelled by the user.
    public static func cancel() {
        TransactionStore.shared.cancel()
    }

}
#endif
