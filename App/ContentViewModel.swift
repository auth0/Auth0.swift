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

    // My Account Profile
    @Published var profileFieldsFilter: String = ""
    @Published var includeProfileFields: Bool = true
    @Published var profileGivenName: String = ""
    @Published var profileFamilyName: String = ""
    @Published var profileName: String = ""
    @Published var profileNickname: String = ""
    @Published var profilePicture: String = ""
    @Published var profileOutput: String?

    /// The editable profile values as last returned by the API, to tell which fields were edited.
    private var loadedProfileValues = EditableProfileValues()

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
        self.credentialsManager = credentialsManager ?? CredentialsManager(authentication: Auth0.authentication())
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
            // The access token is requested for the My Account API so it can be used for the profile requests.
            var login = webAuth.scope(Self.loginScope)
            if let audience = myAccountAudience {
                login = login.audience(audience)
            }
            _ = try await login.start()
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
        do {
            let credentials = try await authenticationClient
                .login(passkey: passkey,
                       challenge: challenge,
                       connection: "Username-Password-Authentication",
                       audience: myAccountAudience,
                       scope: Self.loginScope,
                       verification: collectedVerificationCodes)
                .validateClaims()
                .start()
            try credentialsManager.store(credentials: credentials)
            // Success — clear all pending state.
            clearPendingPasskeySignup()
            isAuthenticated = true
        } catch let error as AuthenticationError where error.isPasskeyVerificationRetryable {
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
                   audience: myAccountAudience,
                   scope: Self.loginScope)
            .validateClaims()
            .start()
        try credentialsManager.store(credentials: credentials)
        isAuthenticated = true
    }
    #endif

    // MARK: - My Account Profile

    private static let profileScope = "read:me:profile update:me:profile"

    /// Scope requested by every login, so that the stored access token can be used for the profile requests.
    private static let loginScope = "openid profile email offline_access \(profileScope)"

    /// The My Account API audience of the configured tenant, e.g. `https://example.auth0.com/me/`.
    private var myAccountAudience: String? {
        authenticationClient.url.host.map { "https://\($0)/me/" }
    }

    /// Fetches the authenticated user's profile, optionally filtered by `profileFieldsFilter` (comma-separated).
    func getProfile() async {
        await runProfileRequest { myAccount in
            let names = self.profileFieldsFilter
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            let options = names.isEmpty ? nil : GetUserProfileOptions(fields: names,
                                                                      includeFields: self.includeProfileFields)
            return try await myAccount.getUserProfile(options: options).start()
        }
    }

    /// Updates the profile attributes that were edited in the text fields.
    ///
    /// Empty and unchanged values are not sent, so a field the user cannot write (for example `given_name` for a user
    /// managed by an identity provider) does not make the whole update fail unless it was edited.
    func updateProfile() async {
        await runProfileRequest { myAccount in
            func edited(_ text: String, from loaded: String?) -> String? {
                return text.isEmpty || text == loaded ? nil : text
            }
            let loaded = self.loadedProfileValues
            let request = UpdateUserProfileRequest(givenName: edited(self.profileGivenName, from: loaded.givenName),
                                                   familyName: edited(self.profileFamilyName, from: loaded.familyName),
                                                   name: edited(self.profileName, from: loaded.name),
                                                   nickname: edited(self.profileNickname, from: loaded.nickname),
                                                   picture: edited(self.profilePicture, from: loaded.picture))
            return try await myAccount.updateUserProfile(request).start()
        }
    }

    private func runProfileRequest(_ request: (MyAccountAuthenticationMethods) async throws -> MyAccountProfile) async {
        isLoading = true
        errorMessage = nil
        profileOutput = nil
        do {
            guard let host = authenticationClient.url.host else {
                errorMessage = "Could not determine the Auth0 domain"
                isLoading = false
                return
            }
            // Web login and passkey login request the My Account audience, so the stored access token is the one to use.
            let credentials = try await credentialsManager.credentials()
            let myAccount = Auth0.myAccount(token: credentials.accessToken, domain: host).authenticationMethods
            let profile = try await request(myAccount)
            populateProfileInputs(from: profile)
            profileOutput = describe(profile)
        } catch let error as CredentialsManagerError {
            errorMessage = handleCredentialsManagerError(error)
        } catch let error as MyAccountError {
            errorMessage = describe(error)
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func populateProfileInputs(from profile: MyAccountProfile) {
        // A profile requested with `fields` can omit some values: keep what was loaded before for those.
        loadedProfileValues.givenName = profile.givenName ?? loadedProfileValues.givenName
        loadedProfileValues.familyName = profile.familyName ?? loadedProfileValues.familyName
        loadedProfileValues.name = profile.name ?? loadedProfileValues.name
        loadedProfileValues.nickname = profile.nickname ?? loadedProfileValues.nickname
        loadedProfileValues.picture = profile.picture ?? loadedProfileValues.picture

        profileGivenName = profile.givenName ?? profileGivenName
        profileFamilyName = profile.familyName ?? profileFamilyName
        profileName = profile.name ?? profileName
        profileNickname = profile.nickname ?? profileNickname
        profilePicture = profile.picture ?? profilePicture
    }

    private func describe(_ profile: MyAccountProfile) -> String {
        var lines: [String] = []
        func add(_ key: String, _ value: Any?) {
            if let value { lines.append("\(key): \(value)") }
        }
        add("user_id", profile.userId)
        add("given_name", profile.givenName)
        add("family_name", profile.familyName)
        add("name", profile.name)
        add("nickname", profile.nickname)
        add("picture", profile.picture)
        add("email", profile.email)
        add("email_verified", profile.emailVerified)
        add("phone_number", profile.phoneNumber)
        add("phone_verified", profile.phoneVerified)
        add("username", profile.username)
        add("created_at", profile.createdAt)
        add("updated_at", profile.updatedAt)
        if let policy = profile.profilePolicy {
            lines.append("profile_policy:")
            for (pointer, entry) in policy.sorted(by: { $0.key < $1.key }) {
                let reason = entry.reason.map { " (\($0))" } ?? ""
                lines.append("  \(pointer): \(entry.access.rawValue), \(entry.source.rawValue)\(reason)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func describe(_ error: MyAccountError) -> String {
        var message = "My Account error (\(error.statusCode)) \(error.code): \(error.localizedDescription)"
        for validationError in error.validationErrors ?? [] {
            message += "\n• \(validationError.pointer ?? "?"): \(validationError.detail)"
        }
        return message
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

/// The profile attributes that can be edited in the demo app.
private struct EditableProfileValues {
    var givenName: String?
    var familyName: String?
    var name: String?
    var nickname: String?
    var picture: String?
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
