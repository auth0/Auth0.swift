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
    /// The connection the flow runs against. Change it to try connections that collect a password at sign-up
    /// (required or optional) and ones that do not.
    @Published var connection: String = "Username-Password-Authentication"
    @Published var isLoading: Bool = false
    @Published var embeddedAuthUIState: EmbeddedAuthUIState = .initial
    @Published var attemptError: String?
    /// All actions offered by the latest continuation. Indices come from each entry's own `index` field.
    @Published var availableActions: [NextAction] = []
    /// The identifiers sign-up collects and whether each is required, from the `signup` action of the first response.
    @Published private(set) var signupIdentifiers: [SignupIdentifier] = []

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
    /// Identifiers from the first screen that were already sent, so each is submitted automatically only once.
    private var submittedIdentifiers = Set<IdentifierType>()
    /// Whether the running flow is a sign-up, started with the Signup button.
    private var isSigningUp = false
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

    /// Starts the flow with the email or phone number entered on the first screen.
    ///
    /// Login advertises every capability except sign-up, so the server never offers it. Sign-up advertises just the
    /// capabilities it uses, calls `signup()` as soon as the server offers it, and then submits the email and the
    /// phone number that were entered as the server asks for them.
    func startEmbeddedFlow(signingUp: Bool = false) async {
        isLoading = true
        // A cancelled poll may still have a request in flight that mutates the SDK's session,
        // so wait for it to finish before starting a new flow.
        cancelPolling()
        await pollTask?.value
        pollTask = nil
        clearFlowState()
        isSigningUp = signingUp
        embeddedAuthUIState = .initial
        do {
            _ = try await embeddedAuthClient.authorize(connection: connection,
                                                       capabilities: capabilities(signingUp: signingUp),
                                                       scope: "openid profile email offline_access",
                                                       audience: nil).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
        if signingUp {
            if case .failed = embeddedAuthUIState { return }
            // Without the sign-up action this would only be a login with fewer capabilities, so stop instead.
            guard canSignUp else {
                clearFlowState()
                embeddedAuthUIState = .failed("Sign-up is not enabled for this connection.")
                return
            }
            await startSignup()
        }
        await submitEnteredIdentifier()
    }

    /// The capabilities to advertise. Login never advertises sign-up. Sign-up advertises only what it needs: the
    /// email and phone identify and challenge steps, the OTP verification, and the sign-up actions. That lets the
    /// server ask for each identifier it collects (an email, a phone number, or both) whatever was entered first.
    private func capabilities(signingUp: Bool) -> [EmbeddedCapability] {
        guard signingUp else {
            return EmbeddedCapability.all.filter { $0 != .signup && $0 != .confirmSignup }
        }
        return [.signup, .identifyEmail, .identifyPhone, .challengeEmail, .challengePhone, .verifyOTP, .confirmSignup]
    }

    /// The identifier from the first screen to send next: the email, then the phone number, each at most once.
    private var pendingIdentifier: IdentifierType? {
        if !email.isEmpty, !submittedIdentifiers.contains(.email) { return .email }
        if !phone.isEmpty, !submittedIdentifiers.contains(.phone) { return .phone }
        return nil
    }

    /// Submits the pending identifier when the flow asks for it. With both an email and a phone number entered,
    /// sign-up identifies and verifies one, then the server asks for the other.
    private func submitEnteredIdentifier() async {
        switch embeddedAuthUIState {
        case .identifyEmail where pendingIdentifier == .email:
            await submitEmail(email)
        case .identifyPhone where pendingIdentifier == .phone:
            await submitPhone(phone)
        default:
            break
        }
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
        submittedIdentifiers.insert(.email)
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
        submittedIdentifiers.insert(.phone)
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
        // A sign-up with several identifiers moves on to the next one entered once this one is verified.
        if isSigningUp {
            await submitEnteredIdentifier()
        }
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

    /// Asks the server to start registering a new user. It never returns credentials: the continuation
    /// carries the next registration step, which `handle(embeddedAuthError:)` presents.
    func startSignup() async {
        isLoading = true
        do {
            try await embeddedAuthClient.signup().start()
            fail(with: EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0))
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    /// Finishes the sign-up. `password` is `nil` when the connection does not collect one, or when the user skips an
    /// optional one. A missing, refused or rejected password comes back as a continuation that offers the
    /// confirmation again, which `handle(embeddedAuthError:)` presents with a message.
    func confirmSignup(password: String? = nil) async {
        isLoading = true
        attemptError = nil
        do {
            let credentials = try await embeddedAuthClient.confirmSignup(password: password).start()
            finish(with: credentials)
        } catch let error as EmbeddedAuthError {
            if case .network = error.reason {
                // The session is kept and the SDK does not keep the password, so the user submits it again.
                attemptError = "A network error occurred. Check your connection and try again."
            } else {
                handle(embeddedAuthError: error)
            }
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    /// Whether the latest continuation offers to register a new user.
    private var canSignUp: Bool {
        availableActions.contains { action in
            if case .signup = action { return true }
            return false
        }
    }

    /// Whether sign-up collects `type` without requiring it, so it can be left empty.
    func isOptional(_ type: IdentifierType) -> Bool {
        signupIdentifiers.first { $0.type == type }.map { !$0.isRequired } ?? false
    }

    /// Whether the server lets the user finish sign-up now. That is how an optional identifier is skipped:
    /// the server only offers `confirmSignup` once every required identifier is verified.
    var canCompleteSignup: Bool {
        availableActions.contains { $0.isConfirmSignup }
    }

    /// Skips the identifier on screen and goes to the sign-up confirmation.
    func skipToConfirmation() {
        guard let confirm = availableActions.first(where: { $0.isConfirmSignup }) else { return }
        _ = present(confirm, among: availableActions)
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
        submittedIdentifiers = []
        signupIdentifiers = []
        isSigningUp = false
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
        case .accessDenied:
            detail = "The request was denied, for example by a sign-up validation. Start again."
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
        // Open the identify screen for the identifier entered on the first screen. This only sets the starting
        // choice, so the user's "use phone / use email instead" toggle still works afterwards.
        if let pending = pendingIdentifier {
            usePhoneIdentifier = pending == .phone
        }
        // Only the first response lists the sign-up identifiers, so keep them for the rest of the flow.
        for case .signup(let identifiers, _) in nextActions {
            signupIdentifiers = identifiers
        }
        switch reason {
        case .invalidCode:
            attemptError = "That code is incorrect. Please try again."
        case .invalidIdentifierOrCode:
            attemptError = "That identifier or code is incorrect. Please try again."
        case .invalidIdentifierOrPassword:
            attemptError = "Incorrect username or password. Please try again."
        case .passwordRequired:
            attemptError = "A password is required to create the account."
        case .passwordNotAccepted:
            attemptError = "This connection does not use a password. Continue without one."
        case .invalidPassword:
            attemptError = "That password does not meet the requirements. Please try another one."
        default:
            attemptError = nil
        }
        // The server offers `confirmSignup` only when every required identifier is verified. If it also still asks
        // for an identifier the user entered, send that first. Otherwise any identifier still offered is optional
        // and was left empty, so skip it. Whatever order the server lists the actions in, the result is the same.
        if let confirm = nextActions.first(where: { $0.isConfirmSignup }), attemptError == nil {
            if let pending = pendingIdentifier, offersEnteredIdentifier(in: nextActions) {
                _ = present(pending == .email ? .identifyEmail : .identifyPhone, among: nextActions)
            } else {
                _ = present(confirm, among: nextActions)
            }
            return
        }
        for action in nextActions where present(action, among: nextActions) {
            return
        }
        fail(with: error)
    }

    /// Whether `actions` asks for an identifier the user entered on the first screen and that is not sent yet.
    func offersEnteredIdentifier(in actions: [NextAction]) -> Bool {
        switch pendingIdentifier {
        case .email?: return actions.contains(.identifyEmail)
        case .phone?: return actions.contains(.identifyPhone)
        default: return false
        }
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
        case .confirmSignup(let signupPassword):
            // The field is empty on every visit, so a rejected password is never shown again.
            password = ""
            embeddedAuthUIState = .confirmSignup(password: signupPassword)
        case .signup, .unknown:
            // Sign-up has no screen of its own: `startEmbeddedFlow(signingUp:)` calls `signup()` when it is offered.
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
    case confirmSignup(password: SignupPassword?)
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

private extension NextAction {
    var isConfirmSignup: Bool {
        if case .confirmSignup = self { return true }
        return false
    }
}
