import Testing
import Foundation
import Combine
@testable import Auth0
@testable import OAuth2

// MARK: - MockRequestable

/// Generic test double for `Requestable`. Immediately delivers a predetermined result.
struct MockRequestable<T: Sendable, E: Auth0APIError>: Requestable {
    let result: Result<T, E>

    func start(_ callback: @escaping (Result<T, E>) -> Void) {
        callback(result)
    }

    func parameters(_ extraParameters: [String: Any]) -> any Requestable<T, E> { self }
    func headers(_ extraHeaders: [String: String]) -> any Requestable<T, E> { self }
    func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<T, E> { self }
}

// MARK: - StubRequestable

/// A no-op requestable used for Authentication protocol methods not under test.
private struct StubRequestable<T: Sendable, E: Auth0APIError>: Requestable {
    func start(_ callback: @escaping (Result<T, E>) -> Void) {}
    func parameters(_ extraParameters: [String: Any]) -> any Requestable<T, E> { self }
    func headers(_ extraHeaders: [String: String]) -> any Requestable<T, E> { self }
    func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<T, E> { self }
}

// MARK: - MockAuthentication

/// Test double for `Authentication`. Injects a `Requestable` for the login method under test;
/// all other protocol methods return no-op stubs.
struct MockAuthentication: Authentication {
    var clientId: String
    var url: URL
    var dpop: DPoP?
    var auth0ClientInfo: Auth0ClientInfo
    var logger: (any Logger)?

    /// The request returned by `login(usernameOrEmail:password:realmOrConnection:audience:scope:)`.
    let loginRequest: any Requestable<Credentials, AuthenticationError>

    init(loginRequest: any Requestable<Credentials, AuthenticationError>,
         clientId: String = "mock-client",
         url: URL = URL(string: "https://mock.auth0.com")!) {
        self.loginRequest = loginRequest
        self.clientId = clientId
        self.url = url
        self.dpop = nil
        self.auth0ClientInfo = Auth0ClientInfo()
        self.logger = nil
    }

    // MARK: Method under test

    func login(usernameOrEmail username: String, password: String,
               realmOrConnection realm: String,
               audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> {
        TokenRequest(request: loginRequest, authentication: self)
    }

    // MARK: Required stubs

    func login(email: String, code: String, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func login(phoneNumber: String, code: String, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func login(withOTP otp: String, mfaToken: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func login(withOOBCode oobCode: String, mfaToken: String, bindingCode: String?) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func login(withRecoveryCode recoveryCode: String, mfaToken: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func multifactorChallenge(mfaToken: String, types: [String]?, authenticatorId: String?) -> any Requestable<Challenge, AuthenticationError> { StubRequestable() }
    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents?, profile: [String: Any]?, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func loginDefaultDirectory(withUsername username: String, password: String, audience: String?, scope: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func signup(email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, rootAttributes: [String: Any]?) -> any Requestable<DatabaseUser, AuthenticationError> { StubRequestable() }

    #if PASSKEYS_PLATFORM
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: LoginPasskey, challenge: PasskeyLoginChallenge, connection: String?, audience: String?, scope: String, organization: String?) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyLoginChallenge(connection: String?, organization: String?) -> any Requestable<PasskeyLoginChallenge, AuthenticationError> { StubRequestable() }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func login(passkey: SignupPasskey, challenge: PasskeySignupChallenge, connection: String?, audience: String?, scope: String, organization: String?) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }

    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeySignupChallenge(email: String?, phoneNumber: String?, username: String?, name: String?, connection: String?, organization: String?) -> any Requestable<PasskeySignupChallenge, AuthenticationError> { StubRequestable() }
    #endif

    func resetPassword(email: String, connection: String) -> any Requestable<Void, AuthenticationError> { StubRequestable() }
    func startPasswordless(email: String, type: PasswordlessType, connection: String) -> any Requestable<Void, AuthenticationError> { StubRequestable() }
    func startPasswordless(phoneNumber: String, type: PasswordlessType, connection: String) -> any Requestable<Void, AuthenticationError> { StubRequestable() }
    func userInfo(withAccessToken accessToken: String, tokenType: String) -> any Requestable<UserProfile, AuthenticationError> { StubRequestable() }
    func codeExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func ssoExchange(withRefreshToken refreshToken: String) -> any TokenRequestable<SSOCredentials, AuthenticationError> { TokenRequest(request: StubRequestable() as any Requestable<SSOCredentials, AuthenticationError>, authentication: self) }
    func renew(withRefreshToken refreshToken: String, audience: String?, scope: String?) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
    func revoke(refreshToken: String) -> any Requestable<Void, AuthenticationError> { StubRequestable() }
    func jwks() -> any Requestable<JWKS, AuthenticationError> { StubRequestable() }
    func customTokenExchange(subjectToken: String, subjectTokenType: String, audience: String?, scope: String, organization: String?, parameters: [String: Any]) -> any TokenRequestable<Credentials, AuthenticationError> { TokenRequest(request: StubRequestable(), authentication: self) }
}

// MARK: - Stubs

private extension CredentialsManager {
    static var dummy: CredentialsManager {
        CredentialsManager(authentication: Auth0.authentication(clientId: "test-client", domain: "test.auth0.com"))
    }
}

private extension Credentials {
    static var stub: Credentials {
        Credentials(accessToken: "access-token", tokenType: "Bearer", idToken: "id-token")
    }
}

private extension AuthenticationError {
    static var stub: AuthenticationError {
        AuthenticationError(info: ["error": "access_denied", "error_description": "Access denied"], statusCode: 401)
    }
}

// MARK: - ContentViewModelTests

@MainActor
@Suite("ContentViewModel")
struct ContentViewModelTests {

    private func makeViewModel(
        email: String = "",
        password: String = "",
        isAuthenticated: Bool = false,
        loginRequest: any Requestable<Credentials, AuthenticationError>
    ) -> ContentViewModel {
        ContentViewModel(
            email: email,
            password: password,
            isAuthenticated: isAuthenticated,
            authenticationClient: MockAuthentication(loginRequest: loginRequest),
            credentialsManager: .dummy
        )
    }

    // MARK: Initial state

    @Test("Default initial state has empty fields and no error")
    func defaultInitialState() {
        let viewModel = makeViewModel(loginRequest: MockRequestable(result: .success(.stub)))

        #expect(viewModel.email == "")
        #expect(viewModel.password == "")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Custom initial state is reflected in published properties")
    func customInitialState() {
        let viewModel = makeViewModel(
            email: "user@example.com",
            password: "secret",
            isAuthenticated: true,
            loginRequest: MockRequestable(result: .success(.stub))
        )

        #expect(viewModel.email == "user@example.com")
        #expect(viewModel.password == "secret")
        #expect(viewModel.isAuthenticated == true)
    }

    // MARK: login() — success

    @Test("login() sets isAuthenticated to true on success")
    func loginSuccessSetsAuthenticated() async {
        let viewModel = makeViewModel(loginRequest: MockRequestable(result: .success(.stub)))

        await viewModel.login()

        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("login() clears isLoading after success")
    func loginSuccessClearsLoading() async {
        let viewModel = makeViewModel(loginRequest: MockRequestable(result: .success(.stub)))

        await viewModel.login()

        #expect(viewModel.isLoading == false)
    }

    // MARK: login() — failure

    @Test("login() sets errorMessage and keeps isAuthenticated false on failure")
    func loginFailureSetsErrorMessage() async {
        let viewModel = makeViewModel(loginRequest: MockRequestable(result: .failure(.stub)))

        await viewModel.login()

        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.errorMessage == AuthenticationError.stub.localizedDescription)
    }

    @Test("login() clears isLoading after failure")
    func loginFailureClearsLoading() async {
        let viewModel = makeViewModel(loginRequest: MockRequestable(result: .failure(.stub)))

        await viewModel.login()

        #expect(viewModel.isLoading == false)
    }

    // MARK: login() — uses injected request

    @Test("login() uses the injected Authentication client, not a live network call")
    func loginUsesInjectedAuthenticationClient() async {
        // The mock always succeeds; a live Auth0 call would fail without network/credentials.
        let viewModel = makeViewModel(
            email: "any@example.com",
            password: "any",
            loginRequest: MockRequestable(result: .success(.stub))
        )

        await viewModel.login()

        #expect(viewModel.isAuthenticated == true)
    }
}
