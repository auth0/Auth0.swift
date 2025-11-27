#if WEB_AUTH_PLATFORM
import Foundation
import LocalAuthentication

struct BioAuthentication {

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

    init(authContext: LAContext,
         evaluationPolicy: LAPolicy,
         title: String,
         cancelTitle: String? = nil,
         fallbackTitle: String? = nil,
         policy: BiometricPolicy = .always
    ) {
        self.authContext = authContext
        self.evaluationPolicy = evaluationPolicy
        self.title = title
        self.policy = policy
        self.cancelTitle = cancelTitle
        self.fallbackTitle = fallbackTitle
    }

    func validateBiometric(callback: @escaping (Error?) -> Void) {
        self.authContext.evaluatePolicy(evaluationPolicy, localizedReason: self.title) {
            guard $1 == nil else { return callback($1) }
            callback($0 ? nil : LAError(.authenticationFailed))
        }
    }

}
#endif
