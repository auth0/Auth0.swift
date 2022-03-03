#if WEB_AUTH_PLATFORM
import Foundation
#if canImport(Combine)
import Combine
#endif

/// Web-based authentication using Auth0.
///
/// - See: ``WebAuthError``
/// - See: [Universal Login](https://auth0.com/docs/login/universal-login)
public protocol WebAuth: Trackable, Loggable {

    /// The Auth0 Client ID.
    var clientId: String { get }
    /// The Auth0 Domain URL.
    var url: URL { get }
    /// The ``Telemetry`` instance.
    var telemetry: Telemetry { get set }

    // MARK: - Builder

    /**
     Specify an Auth0 connection to directly show that Identity Provider's login page, skipping the Universal Login
     page itself. By default no connection is specified, so the Universal Login page will be displayed.

     - Parameter connection: Name of the connection.
     - Returns: The same `WebAuth` instance to allow method chaining.
     */
    func connection(_ connection: String) -> Self

    /**
     Specify the scopes that will be requested during authentication.

     - Parameter scope: Space-separated list of requested scope values. E.g. `openid profile email offline_access`.
     - Returns: The same `WebAuth` instance to allow method chaining.
     - See: [Scopes](https://auth0.com/docs/configure/apis/scopes)
     */
    func scope(_ scope: String) -> Self

    /**
     Specify provider scopes for OAuth2/social connections, e.g. Facebook, Google, etc.

     - Parameter connectionScope: Space-separated list of requested OAuth2/social scope values. E.g. `user_friends email`.
     - Returns: The same `WebAuth` instance to allow method chaining.
     - See: [Connection Scopes](https://auth0.com/docs/authenticate/identity-providers/adding-scopes-for-an-external-idp)
     */
    func connectionScope(_ connectionScope: String) -> Self

    /**
     Specify a `state` parameter that will be sent back after authentication to verify that the response
     corresponds to your request.
     By default a random value is used.

     - Parameter state: State value.
     - Returns: The same `WebAuth` instance to allow method chaining.
     */
    func state(_ state: String) -> Self

    /**
     Specify additional parameters for authentication.

     - Parameter parameters: Additional authentication parameters.
     - Returns: The same `WebAuth` instance to allow method chaining.
     */
    func parameters(_ parameters: [String: String]) -> Self

    /// Specify a custom redirect URL to be used.
    ///
    /// - Parameter redirectURL: Custom redirect URL.
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    func redirectURL(_ redirectURL: URL) -> Self

    ///  Specify an audience name for the API that your application will call using the Access Token returned after
    ///  authentication.
    ///  This value must match the **API Identifier** defined in the APIs section of the [Auth0 Dashboard](https://manage.auth0.com/#/apis).
    ///
    /// - Parameter audience: Audience value. E.g. `https://example.com/api`.
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    /// - See: [Audience](https://auth0.com/docs/secure/tokens/access-tokens/get-access-tokens#control-access-token-audience)]
    func audience(_ audience: String) -> Self

    /// Specify a `nonce` parameter for ID Token validation.
    ///
    /// - Parameter nonce: Nonce value.
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    func nonce(_ nonce: String) -> Self

    /// Specify a custom issuer for ID Token validation.
    /// This value will be used instead of the Auth0 Domain.
    ///
    /// - Parameter issuer: Custom issuer value. E.g. `https://example.com/`.
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    func issuer(_ issuer: String) -> Self

    /// Specify a leeway amount for ID Token validation.
    /// This value represents the clock skew for the validation of date claims, e.g. `exp`.
    ///
    /// - Parameter leeway: Number of milliseconds. Defaults to `60_000` (1 minute).
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    func leeway(_ leeway: Int) -> Self

    /// Specify a `max_age` parameter for authentication.
    /// Sending this parameter will require the presence of the `auth_time` claim in the ID Token.
    ///
    /// - Parameter maxAge: Number of milliseconds.
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    func maxAge(_ maxAge: Int) -> Self

    /// Use a private browser session to avoid storing the session cookie in the shared cookie jar.
    ///
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    /// - Requires: iOS 13+ or macOS. Has no effect on iOS 12.
    /// - Important: This method will disable Single Sign On (SSO).
    /// - See: [prefersEphemeralWebBrowserSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/3237231-prefersephemeralwebbrowsersessio)
    func useEphemeralSession() -> Self

    /// Specify an invitation URL to join an organization.
    ///
    /// - Parameter invitationURL: Invitation URL for the organization.
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    func invitationURL(_ invitationURL: URL) -> Self

    /// Specify an organization identifier to log in to.
    ///
    /// - Parameter organization: ID of the organization.
    /// - Returns: The same `WebAuth` instance to allow method chaining.
    func organization(_ organization: String) -> Self

    func provider(_ provider: @escaping WebAuthProvider) -> Self

    // MARK: - Methods

    /**
     Starts the Web Auth flow.

     ```
     Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with: \(error)")
         }
     }
     ```

     Any ongoing Web Auth session will be automatically cancelled when starting a new one,
     and its corresponding callback with be called with a failure result containing a ``WebAuthError/userCancelled`` error.

     - Parameter callback: Callback that receives a `Result` containing either the user's credentials or an error.
     - Requires: The **Callback URL** to have been added to the **Allowed Callback URLs** field of your Auth0 application settings in the [Dashboard](https://manage.auth0.com/#/applications/).
     */
    func start(_ callback: @escaping (WebAuthResult<Credentials>) -> Void)

    #if compiler(>=5.5) && canImport(_Concurrency)
    /**
     Starts the Web Auth flow.

     ```
     do {
         let credentials = try await Auth0
             .webAuth(clientId: clientId, domain: "samples.auth0.com")
             .start()
         print("Obtained credentials: \(credentials)")
     } catch {
         print("Failed with: \(error)")
     }
     ```

     Any ongoing Web Auth session will be automatically cancelled when starting a new one,
     and it will throw a ``WebAuthError/userCancelled`` error.

     - Returns: The result of the Web Auth flow.
     - Throws: An error of type ``WebAuthError``.
     - Requires: The **Callback URL** to have been added to the **Allowed Callback URLs** field of your Auth0 application settings in the [Dashboard](https://manage.auth0.com/#/applications/).
     */
    #if compiler(>=5.5.2)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func start() async throws -> Credentials
    #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func start() async throws -> Credentials
    #endif
    #endif

    /**
     Starts the Web Auth flow.

     ```
     Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .start()
         .sink(receiveCompletion: { completion in
             if case .failure(let error) = completion {
                 print("Failed with: \(error)")
             }
         }, receiveValue: { credentials in
             print("Obtained credentials: \(credentials)")
         })
         .store(in: &cancellables)
     ```

     Any ongoing Web Auth session will be automatically cancelled when starting a new one,
     and the subscription will complete with a failure result containing a ``WebAuthError/userCancelled`` error.

     - Returns: A type-erased publisher.
     - Requires: The **Callback URL** to have been added to the **Allowed Callback URLs** field of your Auth0 application settings in the [Dashboard](https://manage.auth0.com/#/applications/).
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func start() -> AnyPublisher<Credentials, WebAuthError>

    /**
     Removes the Auth0 session and optionally removes the Identity Provider (IdP) session.

     ```
     Auth0
         .webAuth()
         .clearSession { result in
             switch result {
             case .success:
                 print("Session cookie cleared")
             case .failure(let error):
                 print("Failed with: \(error)")
         }
     ```

     Remove both the Auth0 session and the Identity Provider session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - Parameters:
       - federated: If the Identity Provider session should be removed. Defaults to `false`.
       - callback: Callback that receives a `Result` containing either an empty success case or an error.
     - Requires: The **Callback URL** to have been added to the **Allowed Logout URLs** field of your Auth0 application settings in the [Dashboard](https://manage.auth0.com/#/applications/).
     - Note: You don't need to call this method if you are using ``useEphemeralSession()`` on login, because there will be no shared cookie to remove.
     - See: [Logout](https://auth0.com/docs/login/logout)
     */
    func clearSession(federated: Bool, callback: @escaping (WebAuthResult<Void>) -> Void)

    /**
     Removes the Auth0 session and optionally removes the Identity Provider (IdP) session.

     ```
     Auth0
         .webAuth()
         .clearSession()
         .sink(receiveCompletion: { completion in
             switch completion {
             case .finished:
                 print("Session cookie cleared")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }, receiveValue: {})
         .store(in: &cancellables)
     ```

     Remove both the Auth0 session and the Identity Provider session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true)
         .sink(receiveCompletion: { print($0) },
               receiveValue: {})
         .store(in: &cancellables)
     ```

     - Parameter federated: If the Identity Provider session should be removed. Defaults to `false`.
     - Returns: A type-erased publisher.
     - Requires: The **Callback URL** to have been added to the **Allowed Logout URLs** field of your Auth0 application settings in the [Dashboard](https://manage.auth0.com/#/applications/).
     - Note: You don't need to call this method if you are using ``useEphemeralSession()`` on login, because there will be no shared cookie to remove.
     - See: [Logout](https://auth0.com/docs/login/logout)
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool) -> AnyPublisher<Void, WebAuthError>

    #if compiler(>=5.5) && canImport(_Concurrency)
    /**
     Removes the Auth0 session and optionally removes the Identity Provider (IdP) session.

     ```
     do {
         try await Auth0
             .webAuth(clientId: clientId, domain: "samples.auth0.com")
             .clearSession()
         print("Session cookie cleared")
     } catch {
         print("Failed with: \(error)")
     }
     ```

     Remove both the Auth0 session and the Identity Provider session:

     ```
     try await Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .clearSession(federated: true)
     ```

     - Parameter federated: If the Identity Provider session should be removed. Defaults to `false`.
     - Requires: The **Callback URL** to have been added to the **Allowed Logout URLs** field of your Auth0 application settings in the [Dashboard](https://manage.auth0.com/#/applications/).
     - Note: You don't need to call this method if you are using ``useEphemeralSession()`` on login, because there will be no shared cookie to remove.
     - See: [Logout](https://auth0.com/docs/login/logout)
     */
    #if compiler(>=5.5.2)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool) async throws
    #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func clearSession(federated: Bool) async throws
    #endif
    #endif

}

public extension WebAuth {

    func clearSession(federated: Bool = false, callback: @escaping (WebAuthResult<Void>) -> Void) {
        self.clearSession(federated: federated, callback: callback)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool = false) -> AnyPublisher<Void, WebAuthError> {
        return self.clearSession(federated: federated)
    }

    #if compiler(>=5.5) && canImport(_Concurrency)
    #if compiler(>=5.5.2)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool = false) async throws {
        return try await self.clearSession(federated: federated)
    }
    #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func clearSession(federated: Bool = false) async throws {
        return try await self.clearSession(federated: federated)
    }
    #endif
    #endif

}
#endif
