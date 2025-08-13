import Foundation

/**
 Defines the policy for when a biometric prompt should be shown when using CredentialsManager.
 */
public enum BiometricPolicy: Equatable {
    /// Default behavior. A biometric prompt will be shown for every call to credentials().
    case always
    /// A biometric prompt will be shown only once within the specified timeout period.
    /// - Parameter timeout: The duration in seconds for which the session remains valid.
    case session(timeout: Int)
    /// A biometric prompt will be shown only once while the app is in the foreground.
    /// The session is invalidated by calling `clearBiometricSession()`.
    case appLifecycle
}
