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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var showOTPSheet: Bool = false
    @Published var otpDigits: [String] = Array(repeating: "", count: 6)
    @Published var otpChannel: PasskeyVerificationMethod = .email
    @Published var isRetryingPasskeyVerification: Bool = false

    private let credentialsManager: CredentialsManager
    private let authenticationClient: Authentication

    #if WEB_AUTH_PLATFORM
    private let webAuth: WebAuth
    #endif

    #if PASSKEYS_PLATFORM
    private var pendingPasskeySignupChallenge: PasskeySignupChallenge?
    private var pendingVerificationChannels: [PasskeyVerificationMethod] = []
    private var collectedVerificationCodes: [PasskeyVerificationMethod: String] = [:]
    // Identifiers of the signup in progress, so that resending a code isn't affected by edits to the text fields.
    private var pendingSignupEmail: String?
    private var pendingSignupPhoneNumber: String?
    private var pendingPasskeyWindow: UIWindow?
    // Stored after ASAuthorizationController succeeds so the same credential is reused across OTP retries.
    private var pendingSignupPasskey: AnyObject?
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
         isLoading: Bool = false,
         errorMessage: String? = nil,
         isAuthenticated: Bool = false,
         authenticationClient: Authentication,
         credentialsManager: CredentialsManager? = nil) {
        self.email = email
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.isAuthenticated = isAuthenticated
        self.authenticationClient = authenticationClient
        self.credentialsManager = credentialsManager ?? CredentialsManager(authentication: Auth0.authentication().using(logger: ConsolePrintLogger()))
        #if WEB_AUTH_PLATFORM
        self.webAuth = Auth0
            .webAuth()
            .useCredentialsManager(self.credentialsManager)
        #endif
    }

    // MARK: - Web Auth

    #if WEB_AUTH_PLATFORM
    func webLogin() async {
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

    func webLogout() async {
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
        let signupEmail = email.isEmpty ? nil : email
        let signupPhoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        do {
            let challenge = try await authenticationClient
                .passkeySignupChallenge(
                    email: signupEmail,
                    phoneNumber: signupPhoneNumber,
                    connection: "Username-Password-Authentication",
                    deliveryMethod: signupPhoneNumber == nil ? nil : .voice)
                .start()

            if let channels = challenge.verificationRequired, !channels.isEmpty {
                pendingSignupEmail = signupEmail
                pendingSignupPhoneNumber = signupPhoneNumber
                pendingPasskeySignupChallenge = challenge
                pendingPasskeyWindow = window
                pendingVerificationChannels = channels
                collectedVerificationCodes = [:]
                isLoading = false
                presentNextPasskeyVerificationChannel()
                return
            }

            try await completePasskeySignup(challenge: challenge, window: window)
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
        otpChannel = channel
        showOTPSheet = true
    }

    func resendPasskeyVerificationOTP() async {
        guard #available(iOS 16.6, *) else { return }
        guard pendingSignupEmail != nil || pendingSignupPhoneNumber != nil else { return }
        isLoading = true
        errorMessage = nil
        do {
            let challenge = try await authenticationClient
                .passkeySignupChallenge(
                    email: pendingSignupEmail,
                    phoneNumber: pendingSignupPhoneNumber,
                    connection: "Username-Password-Authentication",
                    deliveryMethod: pendingSignupPhoneNumber == nil ? nil : .voice)
                .start()
            pendingPasskeySignupChallenge = challenge
            pendingVerificationChannels = challenge.verificationRequired ?? []
            collectedVerificationCodes = [:]
            pendingSignupPasskey = nil
            otpDigits = Array(repeating: "", count: 6)
            if #available(iOS 16.6, *) {
                presentNextPasskeyVerificationChannel()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func submitPasskeyVerificationOTP() async {
        let code = otpDigits.joined()
        guard code.count == 6 else {
            errorMessage = "Please enter all 6 digits"
            return
        }
        collectedVerificationCodes[otpChannel] = code
        guard !pendingVerificationChannels.isEmpty else { return }
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
        var codes: [PasskeyVerificationMethod: String] = [PasskeyVerificationMethod.email: "", PasskeyVerificationMethod.phone: collectedVerificationCodes[PasskeyVerificationMethod.phone] ?? ""]

        do {
            let credentials = try await authenticationClient
                .login(passkey: passkey,
                       challenge: challenge,
                       connection: "Username-Password-Authentication",
                       scope: "openid profile email offline_access",
                       verification: codes)
                .validateClaims()
                .start()
            try credentialsManager.store(credentials: credentials)
            // Success — clear all pending state.
            clearPendingPasskeySignup()
            isAuthenticated = true
        } catch let error as AuthenticationError where error.isPasskeyVerificationCodeInvalid {
            // Wrong OTP — the session is still alive. Reuse the auth_session echoed in this response.
            let failedChannels = error.passkeyVerificationRequired ?? pendingPasskeySignupChallenge?.verificationRequired ?? []
            guard !failedChannels.isEmpty else {
                clearPendingPasskeySignup()
                errorMessage = "Verification failed. Please try signing up again."
                isLoading = false
                return
            }
            pendingVerificationChannels = failedChannels.uniqued()
            collectedVerificationCodes = [:]
            if let newSession = error.passkeyAuthSession, let existing = pendingPasskeySignupChallenge {
                pendingPasskeySignupChallenge = PasskeySignupChallenge(
                    authenticationSession: newSession,
                    relyingPartyId: existing.relyingPartyId,
                    userId: existing.userId,
                    userName: existing.userName,
                    challengeData: existing.challengeData,
                    verificationRequired: failedChannels
                )
            }
            isRetryingPasskeyVerification = true
            errorMessage = "Incorrect code. Please try again."
            isLoading = false
            presentNextPasskeyVerificationChannel()
            return
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch let error as AuthenticationError where error.isNetworkError {
            errorMessage = error.localizedDescription
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
        pendingSignupEmail = nil
        pendingSignupPhoneNumber = nil
        pendingVerificationChannels = []
        collectedVerificationCodes = [:]
        isRetryingPasskeyVerification = false
    }

    @available(iOS 16.6, *)
    private func completePasskeySignup(challenge: PasskeySignupChallenge, window: UIWindow?) async throws {
        passkeyController.window = window
        let passkey = try await passkeyController.presentRegistration(challenge: challenge)
        let credentials = try await authenticationClient
            .login(passkey: passkey,
                   challenge: challenge,
                   connection: "Username-Password-Authentication",
                   scope: "openid profile email offline_access")
            .validateClaims()
            .start()
        try credentialsManager.store(credentials: credentials)
        isAuthenticated = true
    }
    #endif

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
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        defer { authController = nil }
        registrationContinuation?.resume(throwing: error)
        registrationContinuation = nil
    }
}
#endif
