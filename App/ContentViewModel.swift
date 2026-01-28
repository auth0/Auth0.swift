import SwiftUI
import Auth0
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    /// Web Authentication using Universal Login (Recommended)
    func webLogin() async {
        isLoading = true
        errorMessage = nil
    
        #if !os(tvOS) && !os(watchOS)
        do {
            let credentials = try await Auth0
                .webAuth()
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
        #endif
        
        isLoading = false
    }
    
    /// Logout and clear stored credentials
    func logout() async {
        isLoading = true
        errorMessage = nil
        #if !os(tvOS) && !os(watchOS)
        do {
            try await Auth0
                .webAuth()
                .clearSession()
            
            // Clear stored credentials
            let cleared = credentialsManager.clear()
            if cleared {
                isAuthenticated = false
                print("Logout successful")
            }
        } catch let error as Auth0Error {
            errorMessage = "Logout failed: \(error.localizedDescription)"
            print("Logout failed with error: \(error)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        #endif
        
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
