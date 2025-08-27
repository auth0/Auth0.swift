import Foundation
import Auth0

/**
 * Examples demonstrating the usage of BiometricPolicy with CredentialsManager.
 * These examples show different scenarios for implementing biometric authentication sessions.
 */

class BiometricPolicyExamples {
    
    // MARK: - Example 1: Always Show Biometric Prompt (Default Behavior)
    
    func exampleAlwaysPolicy() {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        
        // Enable biometrics with default .always policy - prompt shows every time
        credentialsManager.enableBiometrics(withTitle: "Authenticate with Face ID")
        
        // Every call to credentials() will show the biometric prompt
        credentialsManager.credentials { result in
            switch result {
            case .success(let credentials):
                print("Credentials obtained: \(credentials.accessToken)")
            case .failure(let error):
                print("Failed to get credentials: \(error)")
            }
        }
    }
    
    // MARK: - Example 2: Session-Based Biometric Policy
    
    func exampleSessionPolicy() {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        
        // Enable biometrics with session policy - prompt shows once per 300 seconds (5 minutes)
        credentialsManager.enableBiometrics(withTitle: "Authenticate with Face ID", 
                                           policy: .session(timeout: 300))
        
        // First call shows biometric prompt
        credentialsManager.credentials { result in
            switch result {
            case .success(let credentials):
                print("First call - credentials obtained: \(credentials.accessToken)")
                
                // Subsequent calls within 5 minutes won't show prompt
                self.makeSubsequentCall(credentialsManager)
                
            case .failure(let error):
                print("Failed to get credentials: \(error)")
            }
        }
    }
    
    private func makeSubsequentCall(_ credentialsManager: CredentialsManager) {
        // This call won't show biometric prompt if within the timeout period
        credentialsManager.credentials { result in
            switch result {
            case .success(let credentials):
                print("Subsequent call - credentials obtained without prompt: \(credentials.accessToken)")
            case .failure(let error):
                print("Failed to get credentials: \(error)")
            }
        }
    }
    
    // MARK: - Example 3: App Lifecycle-Based Biometric Policy
    
    func exampleAppLifecyclePolicy() {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        
        // Enable biometrics with app lifecycle policy - prompt shows once per app session
        credentialsManager.enableBiometrics(withTitle: "Authenticate with Touch ID", 
                                           policy: .appLifecycle)
        
        // First call shows biometric prompt
        credentialsManager.credentials { result in
            switch result {
            case .success(let credentials):
                print("App session - credentials obtained: \(credentials.accessToken)")
                
                // All subsequent calls in this app session won't show prompt
                // until clearBiometricSession() is called
                
            case .failure(let error):
                print("Failed to get credentials: \(error)")
            }
        }
        
        // Manually clear the session when needed (e.g., when app goes to background)
        // credentialsManager.clearBiometricSession()
    }
    
    // MARK: - Example 4: Initializing CredentialsManager with BiometricPolicy
    
    func exampleInitializerWithPolicy() {
        // Create CredentialsManager with specific biometric policy from the start
        let credentialsManagerWithSession = CredentialsManager(
            authentication: Auth0.authentication(),
            storeKey: "user_credentials",
            biometricPolicy: .session(timeout: 600) // 10 minutes
        )
        
        // Enable biometrics (policy already set during initialization)
        credentialsManagerWithSession.enableBiometrics(withTitle: "Secure Access Required")
        
        // Create CredentialsManager with app lifecycle policy
        let credentialsManagerWithAppLifecycle = CredentialsManager(
            authentication: Auth0.authentication(),
            biometricPolicy: .appLifecycle
        )
        
        credentialsManagerWithAppLifecycle.enableBiometrics(withTitle: "One-time Authentication")
    }
    
    // MARK: - Example 5: Session Management with App State Changes
    
    func exampleSessionManagementWithAppState() {
        let credentialsManager = CredentialsManager(
            authentication: Auth0.authentication(),
            biometricPolicy: .appLifecycle
        )
        
        credentialsManager.enableBiometrics(withTitle: "Authenticate to continue")
        
        // In your AppDelegate or SceneDelegate, you might want to clear the session
        // when the app enters the background:
        
        // NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, 
        //                                        object: nil, 
        //                                        queue: .main) { _ in
        //     credentialsManager.clearBiometricSession()
        // }
        
        // Note: The SDK doesn't automatically add NotificationCenter observers
        // You need to implement this logic in your app as needed
    }
    
    // MARK: - Example 6: Custom Timeout Scenarios
    
    func exampleCustomTimeoutScenarios() {
        // Short session for sensitive operations (1 minute)
        let shortSessionManager = CredentialsManager(
            authentication: Auth0.authentication(),
            biometricPolicy: .session(timeout: 60)
        )
        shortSessionManager.enableBiometrics(withTitle: "High Security Access")
        
        // Long session for user convenience (30 minutes)
        let longSessionManager = CredentialsManager(
            authentication: Auth0.authentication(),
            biometricPolicy: .session(timeout: 1800)
        )
        longSessionManager.enableBiometrics(withTitle: "Extended Session Access")
        
        // Example: Clear session manually when needed
        // longSessionManager.clearBiometricSession()
    }
}
