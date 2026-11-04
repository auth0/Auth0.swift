import SwiftUI
import Auth0

// MARK: - View Model

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var username: String = ""
    @Published var otp: String = ""
    @Published var recoveryCode: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var embeddedAuthUIState: EmbeddedAuthUIState = .initial
    @Published var attemptError: String?
    /// All actions offered by the latest continuation. Indices come from each entry's own `index` field.
    @Published var availableActions: [NextAction] = []

    // My Account Profile
    @Published var profileFieldsFilter: String = ""
    @Published var includeProfileFields: Bool = true
    @Published var profileGivenName: String = ""
    @Published var profileFamilyName: String = ""
    @Published var profileName: String = ""
    @Published var profileNickname: String = ""
    @Published var profilePicture: String = ""
    @Published var profileOutput: String?
    @Published var profileError: String?

    /// The editable profile values as last returned by the API, to tell which fields were edited.
    private var loadedProfileValues = EditableProfileValues()
    /// The credentials of the latest successful login, used for the My Account profile requests.
    private var authenticatedCredentials: Credentials?

    private let authenticationClient: Authentication
    private let embeddedAuthClient: EmbeddedAuth

    /// The action backing the screen currently shown, so it is not offered again as an alternative.
    private var currentAction: NextAction?
    private var usePhoneIdentifier = false
    private var pollTask: Task<Void, Never>?

    private static let minPollIntervalMs = 1_000
    private static let maxPollIntervalMs = 60_000
    private static let maxConsecutiveNetworkFailures = 3

    init(email: String = "",
         authenticationClient: Authentication,
         embeddedAuthClient: EmbeddedAuth? = nil) {
        self.email = email
        self.authenticationClient = authenticationClient
        self.embeddedAuthClient = embeddedAuthClient ?? Auth0.embeddedAuth().logging(enabled: true)
    }

    // MARK: - Embedded auth

    func startEmbeddedFlow() async {
        isLoading = true
        // A cancelled poll may still have a request in flight that mutates the SDK's session,
        // so wait for it to finish before starting a new flow.
        cancelPolling()
        await pollTask?.value
        pollTask = nil
        clearFlowState()
        embeddedAuthUIState = .initial
        do {
            _ = try await embeddedAuthClient.authorize(connection: "Username-Password-Authentication").start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    #if WEB_AUTH_PLATFORM
    func webLogin(presentationWindow window: Auth0WindowRepresentable? = nil) async {
        isLoading = true
        // The access token is requested for the My Account API so it can be used for the profile requests.
        var webAuth: WebAuth = Auth0.webAuth().scope(Self.loginScope)
        if let audience = myAccountAudience {
            webAuth = webAuth.audience(audience)
        }
        if let window {
            webAuth = webAuth.presentationWindow(window)
        }
        do {
            let credentials = try await webAuth.start()
            finish(with: credentials)
        } catch let error as WebAuthError where error == .userCancelled {
            embeddedAuthUIState = .initial
        } catch {
            embeddedAuthUIState = .failed("Web login failed: \(error.localizedDescription)")
        }
        isLoading = false
    }
    #endif

    func submitEmail(_ email: String) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.identify(email, type: .email).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitPhone(_ phone: String) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.identify(phone, type: .phone).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitUsername(_ username: String) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.identify(username, type: .username).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func triggerChallenge(index: Int) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.challengeEmail(index: index).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func triggerPhoneChallenge(index: Int, deliveryMethod: PhoneDeliveryMethod) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.challengePhone(index: index, deliveryMethod: deliveryMethod).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func triggerPushChallenge(index: Int) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.challengePush(index: index).start()
        } catch let error as EmbeddedAuthError {
            // The push is sent successfully when the server answers with a `verifyOob` continuation.
            if case .insufficientAuthorization(_, let nextActions) = error.reason,
               let pollInMs = pollInterval(in: nextActions) {
                availableActions = nextActions
                currentAction = nil
                attemptError = nil
                embeddedAuthUIState = .pollingPush(pollInMs: pollInMs)
                startPolling(initialIntervalMs: pollInMs)
            } else {
                handle(embeddedAuthError: error)
            }
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitOtp(_ otp: String, channel: OtpChannel) async {
        isLoading = true
        let otpType: OtpType = channel == .totp ? .totp : .oob
        do {
            let credentials = try await embeddedAuthClient.verifyOtp(otp, type: otpType).start()
            finish(with: credentials)
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitPassword(_ password: String) async {
        isLoading = true
        do {
            let credentials = try await embeddedAuthClient.verifyPassword(password).start()
            finish(with: credentials)
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitRecoveryCode(_ code: String) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.verifyRecoveryCode(code).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func confirmRecoveryCode() async {
        isLoading = true
        do {
            let credentials = try await embeddedAuthClient.confirmRecoveryCode().start()
            finish(with: credentials)
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Navigation between offered methods

    /// Actions from the latest continuation that the user can switch to without a network call.
    var alternativeActions: [NextAction] {
        availableActions.filter { action in
            switch action {
            case .challengeEmail, .challengePhone, .challengePush, .verifyOTP, .verifyRecoveryCode:
                return action != currentAction
            default:
                return false
            }
        }
    }

    /// Whether the latest continuation offers both email and phone identification.
    var canToggleIdentifier: Bool {
        availableActions.contains(.identifyEmail) && availableActions.contains(.identifyPhone)
    }

    func selectAction(_ action: NextAction) {
        attemptError = nil
        _ = present(action, among: availableActions)
    }

    func toggleIdentifier() {
        usePhoneIdentifier.toggle()
        attemptError = nil
        let action: NextAction = usePhoneIdentifier ? .identifyPhone : .identifyEmail
        _ = present(action, among: availableActions)
    }

    // MARK: - Polling & reset

    /// Cancels any push polling. Does not wait for an in-flight request; `startEmbeddedFlow()` does.
    func cancelPolling() {
        pollTask?.cancel()
        if case .pollingPush = embeddedAuthUIState {
            embeddedAuthUIState = .initial
            clearFlowState()
        }
    }

    /// Cancels polling and clears all flow state and user input.
    func reset() {
        cancelPolling()
        embeddedAuthUIState = .initial
        email = ""
        phone = ""
        username = ""
        otp = ""
        recoveryCode = ""
        password = ""
        clearFlowState()
        authenticatedCredentials = nil
        resetProfile()
    }

    // MARK: - My Account Profile

    private static let profileScope = "read:me:profile update:me:profile"

    /// Scope requested by web login, so that the access token can be used for the profile requests.
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
        profileError = nil
        profileOutput = nil
        do {
            guard let host = authenticationClient.url.host else {
                profileError = "Could not determine the Auth0 domain"
                isLoading = false
                return
            }
            guard let credentials = authenticatedCredentials else {
                profileError = "Log in first to use the My Account API"
                isLoading = false
                return
            }
            // Web login requests the My Account audience, so its access token is the one to use.
            let myAccount = Auth0.myAccount(token: credentials.accessToken, domain: host).authenticationMethods
            let profile = try await request(myAccount)
            populateProfileInputs(from: profile)
            profileOutput = describe(profile)
        } catch let error as MyAccountError {
            profileError = describe(error)
        } catch {
            profileError = "Unexpected error: \(error.localizedDescription)"
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

    private func resetProfile() {
        profileFieldsFilter = ""
        includeProfileFields = true
        profileGivenName = ""
        profileFamilyName = ""
        profileName = ""
        profileNickname = ""
        profilePicture = ""
        profileOutput = nil
        profileError = nil
        loadedProfileValues = EditableProfileValues()
    }
}

private extension ContentViewModel {
    func clearFlowState() {
        availableActions = []
        currentAction = nil
        attemptError = nil
        usePhoneIdentifier = false
    }

    func startPolling(initialIntervalMs: Int) {
        pollTask = Task { [weak self] in
            await self?.pollForPushApproval(initialIntervalMs: initialIntervalMs)
        }
    }

    func pollForPushApproval(initialIntervalMs: Int) async {
        var intervalMs = clamped(initialIntervalMs)
        var networkFailures = 0
        while !Task.isCancelled {
            // Wait before every call, including the first.
            do {
                try await Task.sleep(nanoseconds: UInt64(intervalMs) * 1_000_000)
            } catch {
                return
            }
            guard await pollOnce(intervalMs: &intervalMs, networkFailures: &networkFailures) else { return }
        }
    }

    /// Calls `verifyOob()` once. Returns `false` when polling should stop.
    func pollOnce(intervalMs: inout Int, networkFailures: inout Int) async -> Bool {
        let result: Result<Credentials, Error>
        do {
            result = .success(try await embeddedAuthClient.verifyOob().start())
        } catch {
            result = .failure(error)
        }
        // Cancelling the task does not cancel the request, so a late response is dropped here.
        guard !Task.isCancelled else { return false }
        switch result {
        case .success(let credentials):
            finish(with: credentials)
            return false
        case .failure(let error as EmbeddedAuthError):
            switch error.reason {
            case .insufficientAuthorization(.authorizationPending, let nextActions):
                networkFailures = 0
                availableActions = nextActions
                intervalMs = pollInterval(in: nextActions).map(clamped) ?? intervalMs
                return true
            case .insufficientAuthorization(.slowDown, _):
                networkFailures = 0
                intervalMs = clamped(intervalMs * 2)
                return true
            case .network:
                // The session is preserved, so retry the same step a few times.
                networkFailures += 1
                if networkFailures <= Self.maxConsecutiveNetworkFailures { return true }
                fail(with: error)
                return false
            default:
                handle(embeddedAuthError: error)
                return false
            }
        case .failure(let error):
            embeddedAuthUIState = .failed(error.localizedDescription)
            return false
        }
    }

    func clamped(_ intervalMs: Int) -> Int {
        min(max(intervalMs, Self.minPollIntervalMs), Self.maxPollIntervalMs)
    }

    func pollInterval(in nextActions: [NextAction]) -> Int? {
        for case .verifyOob(let pollInMs) in nextActions {
            return pollInMs
        }
        return nil
    }

    // MARK: - Result handling

    func finish(with credentials: Credentials) {
        authenticatedCredentials = credentials
        phone = ""
        username = ""
        recoveryCode = ""
        password = ""
        clearFlowState()
        embeddedAuthUIState = .success(credentials)
    }

    func fail(with error: EmbeddedAuthError) {
        // Built from the error code and description only; `info` may hold the session or a recovery code.
        let description = error.info["error_description"] as? String
        let detail: String
        switch error.reason {
        case .challengeExpired:
            detail = "The challenge expired. Start again."
        case .authorizationRejected:
            detail = "The request was rejected. Start again."
        case .noEligibleFactors:
            detail = "A second factor is required but none is enrolled. Sign in with a redirect-based flow."
        case .network:
            detail = "A network error occurred. Check your connection and try again."
        default:
            detail = description ?? ""
        }
        clearFlowState()
        recoveryCode = ""
        password = ""
        embeddedAuthUIState = .failed(detail.isEmpty ? "[\(error.code)]" : "[\(error.code)] \(detail)")
    }

    func handle(embeddedAuthError error: EmbeddedAuthError) {
        guard case .insufficientAuthorization(let reason, let nextActions) = error.reason else {
            fail(with: error)
            return
        }
        availableActions = nextActions
        switch reason {
        case .invalidCode:
            attemptError = "That code is incorrect. Please try again."
        case .invalidIdentifierOrCode:
            attemptError = "That identifier or code is incorrect. Please try again."
        case .invalidIdentifierOrPassword:
            attemptError = "Incorrect username or password. Please try again."
        default:
            attemptError = nil
        }
        for action in nextActions where present(action, among: nextActions) {
            return
        }
        fail(with: error)
    }

    /// Shows the screen for `action`. Returns `false` if the action has no screen.
    func present(_ action: NextAction, among nextActions: [NextAction]) -> Bool {
        currentAction = action
        switch action {
        case .identifyEmail, .identifyPhone:
            // `identifyEmail` would otherwise shadow `identifyPhone`; honour the user's choice when both are offered.
            let offersBoth = nextActions.contains(.identifyEmail) && nextActions.contains(.identifyPhone)
            let showPhone = offersBoth ? usePhoneIdentifier : action == .identifyPhone
            currentAction = showPhone ? .identifyPhone : .identifyEmail
            embeddedAuthUIState = showPhone ? .identifyPhone : .identifyEmail
        case .identifyUsername:
            username = ""
            embeddedAuthUIState = .identifyUsername
        case .challengeEmail(let index, let identifier):
            embeddedAuthUIState = .challengeEmail(index: index, identifier: identifier)
        case .challengePhone(let index, let identifier, let deliveryMethods):
            embeddedAuthUIState = .challengePhone(index: index, identifier: identifier, deliveryMethods: deliveryMethods)
        case .challengePush(let index, let name):
            embeddedAuthUIState = .challengePush(index: index, name: name)
        case .verifyOTP(let channel, let identifier):
            otp = ""
            embeddedAuthUIState = .verifyOTP(channel: channel, identifier: identifier)
        case .verifyPassword:
            password = ""
            embeddedAuthUIState = .verifyPassword
        case .verifyOob(let pollInMs):
            // State only: the polling loop is started by `triggerPushChallenge(index:)`.
            embeddedAuthUIState = .pollingPush(pollInMs: pollInMs)
        case .verifyRecoveryCode:
            recoveryCode = ""
            embeddedAuthUIState = .verifyRecoveryCode
        case .confirmRecoveryCode(let newCode):
            embeddedAuthUIState = .confirmRecoveryCode(newCode: newCode)
        case .unknown:
            currentAction = nil
            return false
        }
        return true
    }
}

// MARK: - Embedded Auth UI State

enum EmbeddedAuthUIState {
    case initial
    case identifyEmail
    case identifyPhone
    case identifyUsername
    case challengeEmail(index: Int, identifier: String)
    case challengePhone(index: Int, identifier: String, deliveryMethods: [PhoneDeliveryMethod])
    case challengePush(index: Int, name: String)
    case pollingPush(pollInMs: Int)
    case verifyOTP(channel: OtpChannel, identifier: String?)
    case verifyPassword
    case verifyRecoveryCode
    case confirmRecoveryCode(newCode: String)
    case success(Credentials)
    case failed(String)
}

/// The profile attributes that can be edited in the demo app.
private struct EditableProfileValues {
    var givenName: String?
    var familyName: String?
    var name: String?
    var nickname: String?
    var picture: String?
}
