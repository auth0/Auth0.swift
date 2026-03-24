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
    }

    func login() async {
        isLoading = true
        do {
            let credentials = try await authenticationClient
                .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication", audience: nil, scope: "openid profile email offline_access")
                .validateClaims()
                .start()
            isAuthenticated = true
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
            let credentials = try await Auth0
                .webAuth()
                .scope("openid profile email offline_access")
                .start()

            try credentialsManager.store(credentials: credentials)
            isAuthenticated = true
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
            try await Auth0.webAuth().logout()

            try credentialsManager.clear()
            isAuthenticated = false
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
            let credentials = try await credentialsManager.credentials()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
