import SwiftUI
import Auth0
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    private let credentialsManager: CredentialsManager

    private let authenticationClient: Authentication
    #if WEB_AUTH_PLATFORM
    private let webAuth: WebAuth
    #endif
    init(email: String = "",
         password: String = "",
         isLoading: Bool = false,
         errorMessage: String? = nil,
         isAuthenticated: Bool = false,
         authenticationClient: Authentication,
         credentialsManager: CredentialsManager? = nil) {
        self.email = email
        self.password = password
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.isAuthenticated = isAuthenticated
        self.authenticationClient = authenticationClient
        self.credentialsManager = credentialsManager ?? CredentialsManager(authentication: Auth0.authentication())
        #if WEB_AUTH_PLATFORM
        self.webAuth = Auth0
            .webAuth()
            .useCredentialsManager(self.credentialsManager)
        #endif
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let credentials = try await authenticationClient
                .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication", audience: nil, scope: "openid profile email offline_access")
                .validateClaims()
                .start()
            try credentialsManager.store(credentials: credentials)
            isAuthenticated = true
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    #if WEB_AUTH_PLATFORM
    func webLogin(presentationWindow window: Auth0WindowRepresentable? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let credentials = try await webAuth
                .scope("openid profile email offline_access")
                .start()

            isAuthenticated = true
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch let error as Auth0Error {
            errorMessage = "Login failed: \(error.localizedDescription)"
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }
    #endif

    #if WEB_AUTH_PLATFORM
    func logout(presentationWindow window: Auth0WindowRepresentable? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            try await webAuth.logout()

            isAuthenticated = false
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch let error as Auth0Error {
            errorMessage = "Logout failed: \(error.localizedDescription)"
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }
    #endif

    func checkAuthentication() async {
        do {
            _ = try await credentialsManager.credentials()
            isAuthenticated = true
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
            isAuthenticated = false
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            isAuthenticated = false
        }
    }

    private func handleCredentialsManagerError(_ error: CredentialsManagerError) -> String {
        switch error {
        case CredentialsManagerError.noCredentials:
            return "No credentials found. Please log in again."
        case CredentialsManagerError.noRefreshToken:
            return "Session expired. Please log in again."
        case CredentialsManagerError.renewFailed:
            return "Failed to renew credentials: \(error.cause?.localizedDescription ?? "Unknown error")"
        case CredentialsManagerError.storeFailed:
            return "Failed to save credentials. Please try again."
        case CredentialsManagerError.clearFailed:
            return "Failed to clear credentials. Please try again."
        case CredentialsManagerError.biometricsFailed:
            return "Biometric authentication failed. Please try again."
        case CredentialsManagerError.revokeFailed:
            return "Failed to revoke session: \(error.cause?.localizedDescription ?? "Unknown error")"
        default:
            return "Credentials error: \(error.localizedDescription)"
        }
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
