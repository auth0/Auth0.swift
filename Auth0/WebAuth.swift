// swiftlint:disable file_length

#if WEB_AUTH_PLATFORM
import Foundation
#if canImport(Combine)
import Combine
#endif

/// WebAuth Authentication using Auth0.
public protocol WebAuth: Trackable, Loggable {
    var clientId: String { get }
    var url: URL { get }
    var telemetry: Telemetry { get set }

    /**
     Specify a connection name to be used to authenticate.
     By default no connection is specified, so the Universal Login page will be displayed.

     - Parameter connection: Name of the connection to use.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func connection(_ connection: String) -> Self

    /**
     Scopes that will be requested during auth.

     - Parameter scope: A scope value like: `openid profile email offline_access`.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func scope(_ scope: String) -> Self

    /**
     Provider scopes for oauth2/social connections. e.g. Facebook, Google etc.

     - Parameter connectionScope: OAuth2/social comma separated scope list: `user_friends,email`.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func connectionScope(_ connectionScope: String) -> Self

    /**
     State value that will be echoed after authentication
     in order to check that the response is from your request and not other.
     By default a random value is used.

     - Parameter state: A state value to send with the auth request.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func state(_ state: String) -> Self

    /**
     Send additional parameters for authentication.

     - Parameter parameters: Additional auth parameters.
     - Returns: The same WebAuth instance to allow method chaining.
     */
    func parameters(_ parameters: [String: String]) -> Self

    /// Specify a custom redirect url to be used.
    ///
    /// - Parameter redirectURL: Custom redirect url.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func redirectURL(_ redirectURL: URL) -> Self

    /// Add `nonce` parameter for ID Token validation.
    ///
    /// - Parameter nonce: A nonce string.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func nonce(_ nonce: String) -> Self

    ///  Audience name of the API that your application will call using the `access_token` returned after Auth.
    ///  This value must match the one defined in Auth0 Dashboard [APIs Section](https://manage.auth0.com/#/apis).
    ///
    /// - Parameter audience: An audience value like: `https://someapi.com/api`.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func audience(_ audience: String) -> Self

    /// Specify a custom issuer for ID Token validation.
    /// This value will be used instead of the Auth0 domain.
    ///
    /// - Parameter issuer: A custom issuer value like: `https://example.com/`.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func issuer(_ issuer: String) -> Self

    /// Add a leeway amount for ID Token validation.
    /// This value represents the clock skew for the validation of date claims e.g. `exp`.
    ///
    /// - Parameter leeway: Number of milliseconds. Defaults to `60000` (1 minute).
    /// - Returns: The same WebAuth instance to allow method chaining.
    func leeway(_ leeway: Int) -> Self

    /// Add `max_age` parameter for authentication, only when response type `.idToken` is specified.
    /// Sending this parameter will require the presence of the `auth_time` claim in the ID Token.
    ///
    /// - Parameter maxAge: Number of milliseconds.
    /// - Returns: The same WebAuth instance to allow method chaining.
    func maxAge(_ maxAge: Int) -> Self

    /// Disable Single Sign On (SSO) on iOS 13+ and macOS.
    /// Has no effect on older versions of iOS.
    ///
    /// - Returns: The same WebAuth instance to allow method chaining.
    func useEphemeralSession() -> Self

    /// Specify an invitation URL to join an organization.
    ///
    /// - Parameter invitationURL: An organization invitation URL
    /// - Returns: The same WebAuth instance to allow method chaining.
    func invitationURL(_ invitationURL: URL) -> Self

    /// Specify an organization id to log in to.
    ///
    /// - Parameter organization: An organization id.
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

     Any on going WebAuth Auth session will be automatically cancelled when starting a new one,
     and it's corresponding callback with be called with a failure result of `WebAuthError.userCancelled`.

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

     Any on going WebAuth Auth session will be automatically cancelled when starting a new one,
     and it will throw a `WebAuthError.userCancelled` error.

     - Returns: The result of the WebAuth flow.
     - Throws: An error of type `WebAuthError`.
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

     Any on going WebAuth Auth session will be automatically cancelled when starting a new one,
     and the subscription will complete with a failure result of `WebAuthError.userCancelled`.

     - Returns: A type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func publisher() -> AnyPublisher<Credentials, WebAuthError>

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

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

     Remove Auth0 session and remove the IdP session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - Parameters:
       - federated: `Bool` to remove the IdP session. Defaults to `false`.
       - callback: Callback called with bool outcome of the call.
     */
    func clearSession(federated: Bool, callback: @escaping (WebAuthResult<Void>) -> Void)

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession()
         .sink(receiveCompletion: { completion in
             switch completion {
             case .failure(let error):
                 print("Failed with \(error)")
             case .finished:
                 print("Logged out")
             }
         }, receiveValue: { _ in })
         .store(in: &cancellables)
     ```

     Remove Auth0 session and remove the IdP session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true)
         .sink(receiveValue: { print($0) })
         .store(in: &cancellables)
     ```

     - Parameter federated: `Bool` to remove the IdP session. Defaults to `false`.
     - Returns: A type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool) -> AnyPublisher<Void, WebAuthError>

    #if compiler(>=5.5) && canImport(_Concurrency)
    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

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

     Remove Auth0 session and remove the IdP session:

     ```
     try await Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .clearSession(federated: true)
     ```

     - Parameter federated: `Bool` to remove the IdP session. Defaults to `false`.
     - Returns: `Bool` outcome of the call.
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

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

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

     Remove Auth0 session and remove the IdP session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - Parameters:
       - federated: `Bool` to remove the IdP session. Defaults to `false`.
       - callback: Callback called with bool outcome of the call.
     */
    func clearSession(federated: Bool = false, callback: @escaping (WebAuthResult<Void>) -> Void) {
        self.clearSession(federated: federated, callback: callback)
    }

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession()
         .sink(receiveCompletion: { completion in
             switch completion {
             case .failure(let error):
                 print("Failed with \(error)")
             case .finished:
                 print("Logged out")
             }
         }, receiveValue: { _ in })
         .store(in: &cancellables)
     ```

     Remove Auth0 session and remove the IdP session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true)
         .sink(receiveValue: { print($0) })
         .store(in: &cancellables)
     ```

     - Parameter federated: `Bool` to remove the IdP session. Defaults to `false`.
     - Returns: A type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool = false) -> AnyPublisher<Void, WebAuthError> {
        return self.clearSession(federated: federated)
    }

    #if compiler(>=5.5) && canImport(_Concurrency)
    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - See: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

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

     Remove Auth0 session and remove the IdP session:

     ```
     try await Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .clearSession(federated: true)
     ```

     - Parameter federated: `Bool` to remove the IdP session. Defaults to `false`.
     - Returns: `Bool` outcome of the call.
     */
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
