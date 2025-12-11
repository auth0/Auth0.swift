#if WEB_AUTH_PLATFORM
import Foundation
@preconcurrency import LocalAuthentication

struct BioAuthentication: Sendable {

    private let authContext: LAContext
    private let evaluationPolicy: LAPolicy

    let title: String
    let policy: BiometricPolicy
    
    var fallbackTitle: String? {
        get { return self.authContext.localizedFallbackTitle }
        set { self.authContext.localizedFallbackTitle = newValue }
    }

    var cancelTitle: String? {
        get { return self.authContext.localizedCancelTitle }
        set { self.authContext.localizedCancelTitle = newValue }
    }

    var available: Bool {
        return self.authContext.canEvaluatePolicy(evaluationPolicy, error: nil)
    }
    
    /// Creates a new LAContext with the same settings for fresh biometric prompts.
    private func createFreshContext() -> LAContext {
        let newContext = LAContext()
        newContext.localizedFallbackTitle = self.fallbackTitle
        newContext.localizedCancelTitle = self.cancelTitle
        return newContext
    }

    init(authContext: LAContext,
         evaluationPolicy: LAPolicy,
         title: String,
         cancelTitle: String? = nil,
         fallbackTitle: String? = nil,
         policy: BiometricPolicy = .default
    ) {
        self.authContext = authContext
        self.evaluationPolicy = evaluationPolicy
        self.title = title
        self.policy = policy
        self.cancelTitle = cancelTitle
        self.fallbackTitle = fallbackTitle
    }

    func validateBiometric(callback: @escaping (Error?) -> Void) {
        let contextToUse: LAContext
        
        switch self.policy {
        case .default:
            // Use the existing context (preserves current behavior)
            contextToUse = self.authContext
        case .always, .session, .appLifecycle:
            // Create a fresh context to ensure biometric prompt is shown
            contextToUse = self.createFreshContext()
        }
        
        contextToUse.evaluatePolicy(evaluationPolicy, localizedReason: self.title) {
            guard $1 == nil else { return callback($1) }
            callback($0 ? nil : LAError(.authenticationFailed))
        }
    }

}
#endif
