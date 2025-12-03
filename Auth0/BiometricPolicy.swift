#if WEB_AUTH_PLATFORM
import Foundation

/// Defines the policy for when a biometric prompt should be shown when using the Credentials Manager.
public enum BiometricPolicy {
    
    /// Default behavior. Uses the same LAContext instance, allowing the system to manage biometric prompts.
    /// The system may skip the prompt if biometric authentication was recently successful.
    case `default`
    
    /// A biometric prompt will be shown for every call to `credentials()`.
    /// Creates a new LAContext for each authentication to ensure a fresh prompt.
    case always
    
    /// A biometric prompt will be shown only once within the specified timeout period.
    /// Creates a new LAContext for each authentication when the session has expired.
    /// - Parameter timeoutInSeconds: The duration for which the session remains valid.
    case session(timeoutInSeconds: Int)
    
    /// A biometric prompt will be shown only once while the app is in the foreground.
    /// Creates a new LAContext for each authentication when the session has expired.
    /// The session is invalidated by calling `clearBiometricSession()` or after the default timeout.
    /// - Parameter timeoutInSeconds: The duration for which the session remains valid. Defaults to 3600 seconds (1 hour).
    case appLifecycle(timeoutInSeconds: Int = 3600)
}
#endif
