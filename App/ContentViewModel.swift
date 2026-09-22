import SwiftUI
import Auth0
import Combine
#if PASSKEYS_PLATFORM
import AuthenticationServices
#endif

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var showOTPSheet: Bool = false
    @Published var otpDigits: [String] = Array(repeating: "", count: 6)
    @Published var otpContext: OTPContext = .passwordless
    @Published var isRetryingPasskeyVerification: Bool = false

    enum OTPContext {
        case passwordless
        case passkeyVerification(channel: String)
    }

    private var pendingPasswordlessChallenge: PasswordlessChallenge?
    private let credentialsManager: CredentialsManager
    private let authenticationClient: Authentication

    #if PASSKEYS_PLATFORM
    private var pendingPasskeySignupChallenge: PasskeySignupChallenge?
    private var pendingVerificationChannels: [String] = []
    private var collectedVerificationCodes: [String: String] = [:]
    private var pendingPasskeyWindow: UIWindow?
    // Stored after ASAuthorizationController succeeds so the same credential is reused across OTP retries.
    private var pendingSignupPasskey: AnyObject?
    #endif

    #if WEB_AUTH_PLATFORM
    private let webAuth: WebAuth
    #endif

    #if PASSKEYS_PLATFORM
    private var _passkeyController: Any?

    @available(iOS 16.6, *)
    private var passkeyController: PasskeyController {
        if _passkeyController == nil { _passkeyController = PasskeyController() }
        return _passkeyController as! PasskeyController
    }
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

    // MARK: - Password Login

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

    // MARK: - Web Auth

    #if WEB_AUTH_PLATFORM
    func webLogin(presentationWindow window: Auth0WindowRepresentable? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await webAuth
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

    #if os(iOS)
    func webViewLogin() async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await webAuth
                .provider(WebAuthentication.webViewProvider(style: .pageSheet))
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

    // MARK: - Passkeys

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, *)
    func signupWithPasskey(window: UIWindow?) async {
        guard !email.isEmpty || !phoneNumber.isEmpty else {
            errorMessage = "Please enter an email or phone number to sign up with a passkey"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let challenge = try await authenticationClient
                .passkeySignupChallenge(
                    email: email.isEmpty ? nil : email,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                    connection: "Username-Password-Authentication",
                    deliveryMethod: phoneNumber.isEmpty ? nil : .voice)
                .start()

            if let channels = challenge.verificationRequired, !channels.isEmpty {
                pendingPasskeySignupChallenge = challenge
                pendingPasskeyWindow = window
                pendingVerificationChannels = channels
                collectedVerificationCodes = [:]
                isLoading = false
                presentNextPasskeyVerificationChannel()
                return
            }

            try await completePasskeySignup(challenge: challenge, window: window, verification: nil)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            print(error)
        } catch let error as CredentialsManagerError {
            print(error)
            errorMessage = handleCredentialsManagerError(error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @available(iOS 16.6, *)
    private func presentNextPasskeyVerificationChannel() {
        guard let channel = pendingVerificationChannels.first else {
            Task { await finalizePasskeySignupVerification() }
            return
        }
        otpDigits = Array(repeating: "", count: 6)
        otpContext = .passkeyVerification(channel: channel)
        showOTPSheet = true
    }

    func submitPasskeyVerificationOTP() async {
        guard case .passkeyVerification(let channel) = otpContext else { return }
        let code = otpDigits.joined()
        guard code.count == 6 else {
            errorMessage = "Please enter all 6 digits"
            return
        }
        collectedVerificationCodes[channel] = code
        pendingVerificationChannels.removeFirst()
        showOTPSheet = false

        if #available(iOS 16.6, *) {
            presentNextPasskeyVerificationChannel()
        }
    }

    @available(iOS 16.6, *)
    private func finalizePasskeySignupVerification() async {
        guard let challenge = pendingPasskeySignupChallenge else { return }

        isLoading = true
        errorMessage = nil

        // Create the passkey credential once (only after all OTPs are collected), then reuse it across retries.
        let passkey: any SignupPasskey
        if let existing = pendingSignupPasskey as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            passkey = existing
        } else {
            do {
                passkeyController.window = pendingPasskeyWindow
                let registration = try await passkeyController.presentRegistration(challenge: challenge)
                pendingSignupPasskey = registration
                passkey = registration
            } catch let error as ASAuthorizationError where error.code == .canceled {
                clearPendingPasskeySignup()
                isLoading = false
                return
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
        }

        do {
            let credentials = try await authenticationClient
                .login(passkey: passkey,
                       challenge: challenge,
                       connection: "Username-Password-Authentication",
                       scope: "openid profile email offline_access",
                       verification: collectedVerificationCodes.isEmpty ? nil : collectedVerificationCodes)
                .validateClaims()
                .start()
            try credentialsManager.store(credentials: credentials)
            // Success — clear all pending state.
            clearPendingPasskeySignup()
            isAuthenticated = true
        } catch let error as AuthenticationError where error.isPasskeyVerificationRetryable {
            // Wrong OTP or a missing code — the session is still alive. Ask only for the failed channels. 
            let failedChannels = error.passkeyVerificationRequired ?? pendingVerificationChannels
            pendingVerificationChannels = failedChannels.uniqued()
            collectedVerificationCodes = [:]
            isRetryingPasskeyVerification = true
            errorMessage = "Incorrect code. Please try again."
            isLoading = false
            presentNextPasskeyVerificationChannel()
            return
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch {
            // Terminal (exhausted attempts, expired session, unknown session).
            clearPendingPasskeySignup()
            errorMessage = "Session expired. Please try signing up again."
        }
        isLoading = false
    }

    @available(iOS 16.6, *)
    private func clearPendingPasskeySignup() {
        pendingPasskeySignupChallenge = nil
        pendingSignupPasskey = nil
        pendingPasskeyWindow = nil
        pendingVerificationChannels = []
        collectedVerificationCodes = [:]
        isRetryingPasskeyVerification = false
    }

    @available(iOS 16.6, *)
    private func completePasskeySignup(challenge: PasskeySignupChallenge,
                                       window: UIWindow?,
                                       verification: [String: String]?) async throws {
        passkeyController.window = window
        let passkey = try await passkeyController.presentRegistration(challenge: challenge)
        let credentials = try await authenticationClient
            .login(passkey: passkey,
                   challenge: challenge,
                   connection: "Username-Password-Authentication",
                   scope: "openid profile email offline_access",
                   verification: verification)
            .validateClaims()
            .start()
        try credentialsManager.store(credentials: credentials)
        isAuthenticated = true
    }

    @available(iOS 16.6, *)
    func loginWithPasskey(window: UIWindow?) async {
        isLoading = true
        errorMessage = nil
        do {
            let challenge = try await authenticationClient
                .passkeyLoginChallenge(connection: "Username-Password-Authentication")
                .start()
            passkeyController.window = window
            let passkey = try await passkeyController.presentAssertion(challenge: challenge)
            let credentials = try await authenticationClient
                .login(passkey: passkey,
                       challenge: challenge,
                       connection: "Username-Password-Authentication",
                       scope: "openid profile email offline_access")
                .validateClaims()
                .start()
            try credentialsManager.store(credentials: credentials)
            isAuthenticated = true
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // user dismissed the sheet — not an error
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    #endif

    // MARK: - OTP

    func requestOTPChallenge() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email to receive a passwordless code"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let challenge = try await authenticationClient
                .passwordlessChallenge(email: email, connection: "Username-Password-Authentication", allowSignup: true)
                .start()
            pendingPasswordlessChallenge = challenge
            otpDigits = Array(repeating: "", count: 6)
            showOTPSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loginWithOTP() async {
        guard let challenge = pendingPasswordlessChallenge else { return }
        let code = otpDigits.joined()
        guard code.count == 6 else {
            errorMessage = "Please enter all 6 digits"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let credentials = try await authenticationClient
                .login(otp: code, challenge: challenge, scope: "openid profile email offline_access")
                .validateClaims()
                .start()
            try credentialsManager.store(credentials: credentials)
            showOTPSheet = false
            pendingPasswordlessChallenge = nil
            isAuthenticated = true
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Session

    func clearCredentials() {
        errorMessage = nil
        do {
            try credentialsManager.clear()
            isAuthenticated = false
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkAuthentication() async {
        do {
            try await credentialsManager.clearAll()
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

    // MARK: - Error Handling

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

// MARK: - PasskeyController

#if PASSKEYS_PLATFORM
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
final class PasskeyController: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    var window: UIWindow?

    private var registrationContinuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialRegistration, Error>?
    private var assertionContinuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialAssertion, Error>?
    private var authController: ASAuthorizationController?

    func presentRegistration(challenge: PasskeySignupChallenge) async throws -> ASAuthorizationPlatformPublicKeyCredentialRegistration {
        try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
                relyingPartyIdentifier: challenge.relyingPartyId
            )
            let request = provider.createCredentialRegistrationRequest(
                challenge: challenge.challengeData,
                name: challenge.userName,
                userID: challenge.userId
            )
            registrationContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            authController = controller
            controller.performRequests()
        }
    }

    func presentAssertion(challenge: PasskeyLoginChallenge) async throws -> ASAuthorizationPlatformPublicKeyCredentialAssertion {
        try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
                relyingPartyIdentifier: challenge.relyingPartyId
            )
            let request = provider.createCredentialAssertionRequest(challenge: challenge.challengeData)
            assertionContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            authController = controller
            controller.performRequests()
        }
    }

    // MARK: ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        window ?? UIWindow()
    }

    // MARK: ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { authController = nil }
        if let cred = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            registrationContinuation?.resume(returning: cred)
            registrationContinuation = nil
        } else if let cred = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            assertionContinuation?.resume(returning: cred)
            assertionContinuation = nil
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        defer { authController = nil }
        registrationContinuation?.resume(throwing: error)
        registrationContinuation = nil
        assertionContinuation?.resume(throwing: error)
        assertionContinuation = nil
    }
}
#endif
