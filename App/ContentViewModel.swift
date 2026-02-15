import SwiftUI
import Auth0
import Combine

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    #if os(macOS)
    func webLoginWithAS(presentationWindow window: NSWindow? = nil) async {
        isLoading = true
        errorMessage = nil

        #if !os(tvOS) && !os(watchOS)
        do {
            var webAuth = Auth0
                .webAuth()
                .scope("openid profile email offline_access")

            if let window = window {
                webAuth = webAuth.presentationWindow(window)
            }

            let credentials = try await webAuth.start()

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

    func logout(presentationWindow window: NSWindow? = nil) async {
        isLoading = true
        errorMessage = nil
        #if !os(tvOS) && !os(watchOS)
        do {
            var webAuth = Auth0.webAuth()

            if let window = window {
                webAuth = webAuth.presentationWindow(window)
            }

            try await webAuth.clearSession()

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
    #else

    func webLoginWithAS(presentationWindow window: UIWindow? = nil) async {
        isLoading = true
        errorMessage = nil

        #if !os(tvOS) && !os(watchOS)
        do {
            var webAuth = Auth0
                .webAuth()
                .scope("openid profile email offline_access")

            if let window = window {
                webAuth = webAuth.presentationWindow(window)
            }

            let credentials = try await webAuth.start()

            let stored = credentialsManager.store(credentials: credentials)
            if stored {
                isAuthenticated = true
                print("✓ ASWebAuthenticationSession login successful")
                print("Access Token: \(credentials.accessToken)")
            } else {
                errorMessage = "Failed to store credentials"
            }
        } catch let error as Auth0Error {
            errorMessage = "AS login failed: \(error.localizedDescription)"
            print("ASWebAuthenticationSession login failed: \(error)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        #endif

        isLoading = false
    }

    func logout(presentationWindow window: UIWindow? = nil) async {
        isLoading = true
        errorMessage = nil
        #if !os(tvOS) && !os(watchOS)
        do {
            var webAuth = Auth0
                .webAuth()
            
            if let window = window {
                webAuth = webAuth.presentationWindow(window)
            }
            
            try await webAuth
                .clearSession()

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
    #endif
    
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
