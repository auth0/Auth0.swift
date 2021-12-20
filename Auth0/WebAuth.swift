#if WEB_AUTH_PLATFORM
import Foundation
#if canImport(Combine)
import Combine
#endif

/// Web Authentication using Auth0.
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

    /**
     Specify an Auth0 connection to directly show that Identity Provider's login page, skipping the Universal Login
     page itself. By default no connection is specified, so the Universal Login page will be displayed.

     - Parameter connection: Name of the connection to use.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func connection(_ connection: String) -> Self

    /**
     Scopes that will be requested during authentication.

     - Parameter scope: A scope value like: `openid profile email offline_access`.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func scope(_ scope: String) -> Self

    /**
     Provider scopes for OAuth2/social connections, e.g. Facebook, Google etc.

     - Parameter connectionScope: OAuth2/social scope list: `user_friends email`.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func connectionScope(_ connectionScope: String) -> Self

    /**
     State value that will be echoed after authentication
     in order to check that the response is from your request and not other.
     By default a random value is used.

     - Parameter state: A state value to send with the authentication request.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func state(_ state: String) -> Self

    /**
     Send additional parameters for authentication.

     - Parameter parameters: Additional authentication parameters.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func parameters(_ parameters: [String: String]) -> Self

    /// Specify a custom redirect URL to be used.
    ///
    /// - Parameter redirectURL: Custom redirect URL.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func redirectURL(_ redirectURL: URL) -> Self

    ///  Audience name of the API that your application will call using the `access_token` returned after authentication.
    ///  This value must match the one defined in the APIs Section of the [Auth0 Dashboard](https://manage.auth0.com/#/apis).
    ///
    /// - Parameter audience: An audience value like: `https://example.com/api`.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func audience(_ audience: String) -> Self

    /// Add `nonce` parameter for ID Token validation.
    ///
    /// - Parameter nonce: A nonce string.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func nonce(_ nonce: String) -> Self

    /// Specify a custom issuer for ID Token validation.
    /// This value will be used instead of the Auth0 Domain.
    ///
    /// - Parameter issuer: A custom issuer value like: `https://example.com/`.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func issuer(_ issuer: String) -> Self

    /// Add a leeway amount for ID Token validation.
    /// This value represents the clock skew for the validation of date claims, e.g. `exp`.
    ///
    /// - Parameter leeway: Number of milliseconds. Defaults to `60000` (1 minute).
    /// - Returns: The same WebAuth instance to allow method chaining.
    func leeway(_ leeway: Int) -> Self

    /// Add `max_age` parameter for authentication.
    /// Sending this parameter will require the presence of the `auth_time` claim in the ID Token.
    ///
    /// - Parameter maxAge: Number of milliseconds.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func maxAge(_ maxAge: Int) -> Self

    /// Disable Single Sign On (SSO) on iOS 13+ and macOS.
    /// Has no effect on iOS 12.
    ///
    /// - Returns: The same WebAuth instance to allow method chaining.
    func useEphemeralSession() -> Self

    /// Specify an invitation URL to join an organization.
    ///
    /// - Parameter invitationURL: An organization invitation URL
    /// - Returns: The same WebAuth instance to allow method chaining.
    func invitationURL(_ invitationURL: URL) -> Self

    /// Specify an organization ID to log in to.
    ///
    /// - Parameter organization: An organization ID.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func organization(_ organization: String) -> Self

    /**
     Starts the WebAuth flow.

     ```
     Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .start { result in
             switch result {
             case .success(let credentials):
                 print("Obtained credentials: \(credentials)")
             case .failure(let error):
                 print("Failed with \(error)")
         }
     }
     ```

     Any ongoing WebAuth session will be automatically cancelled when starting a new one,
     and its corresponding callback with be called with a failure result of `WebAuthError.userCancelled`.

     - Parameter callback: Callback called with the result of the WebAuth flow.
     */
    func start(_ callback: @escaping (WebAuthResult<Credentials>) -> Void)

    #if compiler(>=5.5) && canImport(_Concurrency)
    /**
     Starts the WebAuth flow.

     ```
     do {
         let credentials = try await Auth0
             .webAuth(clientId: clientId, domain: "samples.auth0.com")
             .start()
         print("Obtained credentials: \(credentials)")
     } catch {
         print("Failed with \(error)")
     }
     ```

     Any ongoing WebAuth session will be automatically cancelled when starting a new one,
     and it will throw a `WebAuthError.userCancelled` error.

     - Returns: The result of the WebAuth flow.
     - Throws: An error of type ``WebAuthError``.
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
     Starts the WebAuth flow.

     ```
     Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .publisher()
         .sink(receiveCompletion: { completion in
             if case .failure(let error) = completion {
                 print("Failed with \(error)")
             }
         }, receiveValue: { credentials in
             print("Obtained credentials: \(credentials)")
         })
         .store(in: &cancellables)
     ```

     Any ongoing WebAuth session will be automatically cancelled when starting a new one,
     and the subscription will complete with a failure result of `WebAuthError.userCancelled`.

     - Returns: A type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func publisher() -> AnyPublisher<Credentials, WebAuthError>

    /**
     Removes Auth0 session and optionally remove the Identity Provider (IdP) session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You need to make sure that the **Callback URL** has been added to the
     **Allowed Logout URLs** field of your Auth0 application settings in the
     [Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession { result in
             switch result {
             case .success:
                 print("Logged out")
             case .failure(let error):
                 print("Failed with \(error)")
         }
     ```

     Remove Auth0 session and the Identity Provider session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - Parameters:
       - federated: `Bool` to remove the Identity Provider session. Defaults to `false`.
       - callback: Callback called with the result of the call.
     */
    func clearSession(federated: Bool, callback: @escaping (WebAuthResult<Void>) -> Void)

    /**
     Removes Auth0 session and optionally remove the Identity Provider (IdP) session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You need to make sure that the **Callback URL** has been added to the
     **Allowed Logout URLs** field of your Auth0 application settings in the
     [Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession()
         .sink(receiveCompletion: { completion in
             switch completion {
             case .finished:
                 print("Logged out")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }, receiveValue: {})
         .store(in: &cancellables)
     ```

     Remove Auth0 session and the Identity Provider session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true)
         .sink(receiveCompletion: { print($0) },
               receiveValue: {})
         .store(in: &cancellables)
     ```

     - Parameter federated: `Bool` to remove the Identity Provider session. Defaults to `false`.
     - Returns: A type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool) -> AnyPublisher<Void, WebAuthError>

    #if compiler(>=5.5) && canImport(_Concurrency)
    /**
     Removes Auth0 session and optionally remove the Identity Provider (IdP) session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You need to make sure that the **Callback URL** has been added to the
     **Allowed Logout URLs** field of your Auth0 application settings in the
     [Dashboard](https://manage.auth0.com/#/applications/).

     ```
     do {
         try await Auth0
             .webAuth(clientId: clientId, domain: "samples.auth0.com")
             .clearSession()
         print("Logged out")
     } catch {
         print("Failed with \(error)")
     }
     ```

     Remove Auth0 session and the Identity Provider session:

     ```
     try await Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .clearSession(federated: true)
     ```

     - Parameter federated: `Bool` to remove the Identity Provider session. Defaults to `false`.
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
