import SwiftUI
import SafariServices
import Auth0
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    private var challenges: [MFAFactor] = []
    @Published var authenticators: [Authenticator]? = nil
    @Published var enrollmentTypes: [MFAFactor]?
    private(set) var mfaToken: String = ""
    private let mfaClient = Auth0.mfa()
    private let authentication = Auth0.authentication()
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    // MARK: - Authentication Methods
    
    /// Login with email and password using Resource Owner Password flow
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let credentials = try await authentication
                .login(
                    usernameOrEmail: email,
                    password: password,
                    realmOrConnection: "Username-Password-Authentication",
                    scope: "openid profile email offline_access"
                )
                .start()
            
            // Store credentials securely
            let stored = credentialsManager.store(credentials: credentials)
            if stored {
                isAuthenticated = true
                print("Access Token: \(credentials.accessToken)")
            } else {
                errorMessage = "Failed to store credentials"
            }
        } catch let error as AuthenticationError {
            print(error)
            enrollmentTypes = error.mfaRequiredErrorPayload?.mfaRequirements.enroll?.uniqued()
            challenges = error.mfaRequiredErrorPayload?.mfaRequirements.challenge?.uniqued() ?? []
            mfaToken = error.mfaRequiredErrorPayload?.mfaToken ?? ""
            do {
                self.authenticators = try await mfaClient.getAuthenticators(mfaToken: mfaToken, factorsAllowed: challenges.map { $0.type }).start()
            } catch {
                errorMessage = "Unexpected error: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Web Authentication using Universal Login (Recommended)
    func webLogin() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let credentials = try await Auth0
                .webAuth()
                .provider(WebAuthentication.webViewProvider())
                .scope("openid profile email offline_access")
                .start()
            
            // Store credentials securely
            let stored = credentialsManager.store(credentials: credentials)
            if stored {
                isAuthenticated = true
                print("Access Token: \(credentials.accessToken)")
            } else {
                errorMessage = "Failed to store credentials"
            }
        } catch let error as Auth0Error {
            errorMessage = "Login failed: \(error.localizedDescription)"
            print("Web login failed with error: \(error)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Logout and clear stored credentials
    func logout() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth0
                .webAuth()
                .provider(WebAuthentication.webViewProvider())
                .clearSession()
    
            
            // Clear stored credentials
            let cleared = credentialsManager.clear()
            if cleared {
                isAuthenticated = false
                email = ""
                password = ""
                print("Logout successful")
            }
        } catch let error as Auth0Error {
            errorMessage = "Logout failed: \(error.localizedDescription)"
            print("Logout failed with error: \(error)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Check if user has valid credentials stored
    func checkAuthentication() async {
        do {
            let credentials = try await credentialsManager.credentials()
            isAuthenticated = true
            print("Valid credentials found: \(credentials.accessToken)")
        } catch {
            isAuthenticated = false
            print("No valid credentials found")
        }
    }
}


extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
