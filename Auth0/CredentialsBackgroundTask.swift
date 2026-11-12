import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Starts and ends background tasks of the operating system.
protocol BackgroundTaskProvider: Sendable {

    /// Starts a background task.
    ///
    /// - Parameters:
    ///   - name:              Name of the task, used for debugging.
    ///   - expirationHandler: Called on the main thread shortly before the background time runs out.
    /// - Returns: The identifier of the task, or `nil` if no task was started.
    func begin(name: String, expirationHandler: @escaping @MainActor @Sendable () -> Void) -> Int?

    /// Ends a background task.
    ///
    /// - Parameter identifier: The identifier that ``begin(name:expirationHandler:)`` returned.
    func end(identifier: Int)

}

/// Uses `UIApplication` where it is available. On the other platforms, no task is started.
struct SystemBackgroundTaskProvider: BackgroundTaskProvider {

    func begin(name: String, expirationHandler: @escaping @MainActor @Sendable () -> Void) -> Int? {
        #if canImport(UIKit) && !os(watchOS)
        guard let application = UIApplication.sharedIfAvailable() else { return nil }
        let identifier = application.beginBackgroundTask(withName: name, expirationHandler: expirationHandler)
        return identifier == .invalid ? nil : identifier.rawValue
        #else
        return nil
        #endif
    }

    func end(identifier: Int) {
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.sharedIfAvailable()?.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: identifier))
        #endif
    }

}

#if canImport(UIKit) && !os(watchOS)
private extension UIApplication {

    // UIApplication.shared is unavailable in app extensions, so look it up at runtime. Background tasks cannot be used
    // from an app extension, so do not return the application there.
    nonisolated static func sharedIfAvailable() -> UIApplication? {
        guard Bundle.main.bundleURL.pathExtension != "appex" else { return nil }
        return UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication
    }

}
#endif

/// Asks the system for extra execution time while a Credentials Manager request is in flight.
///
/// A Credentials Manager request can exchange the refresh token. With refresh token rotation, Auth0 replaces the
/// refresh token as soon as it handles the exchange. If the system suspends the app after that, but before the response
/// arrives and the new refresh token is stored, the Credentials Manager keeps the old refresh token. Once the rotation
/// overlap period has passed, the next renewal sends that old token, Auth0's reuse detection revokes the whole token
/// family, and the user has to log in again.
///
/// The background task keeps the app running until the request finishes and its result is stored, or until the system
/// expires the task. It does not change the request.
///
/// @unchecked is safe here: `identifier` and `hasEnded` are only accessed while holding `lock`.
final class CredentialsBackgroundTask: @unchecked Sendable {

    private let provider: BackgroundTaskProvider
    private let lock = NSLock()
    private var identifier: Int?
    private var hasEnded = false

    init(name: String, provider: BackgroundTaskProvider) {
        self.provider = provider
        // The system terminates the app if an expired task is not ended, so always end it here.
        let identifier = provider.begin(name: name) { self.end() }
        self.lock.lock()
        self.identifier = identifier
        let hasEnded = self.hasEnded
        self.lock.unlock()
        // The task can expire before `begin` returns.
        if hasEnded {
            self.end()
        }
    }

    /// Ends the background task. Safe to call more than once and from any thread.
    func end() {
        self.lock.lock()
        let identifier = self.identifier
        self.identifier = nil
        self.hasEnded = true
        self.lock.unlock()
        if let identifier = identifier {
            self.provider.end(identifier: identifier)
        }
    }

}
