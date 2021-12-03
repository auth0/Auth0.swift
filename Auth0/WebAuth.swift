#if WEB_AUTH_PLATFORM
import Foundation
#if canImport(Combine)
import Combine
#endif

/// WebAuth Authentication using Auth0
public protocol WebAuth: Trackable, Loggable {
    var clientId: String { get }
    var url: URL { get }
    var telemetry: Telemetry { get set }

    /**
     Specify a connection name to be used to authenticate.

     By default no connection is specified, so the hosted login page will be displayed

     - parameter connection: name of the connection to use

     - returns: the same WebAuth instance to allow method chaining
     */
    func connection(_ connection: String) -> Self

    /**
     Scopes that will be requested during auth

     - parameter scope: a scope value like: `openid email`

     - returns: the same WebAuth instance to allow method chaining
     */
    func scope(_ scope: String) -> Self

    /**
     Provider scopes for oauth2/social connections. e.g. Facebook, Google etc

     - parameter connectionScope: oauth2/social comma separated scope list: `user_friends,email`

     - returns: the same WebAuth instance to allow method chaining
     */
    func connectionScope(_ connectionScope: String) -> Self

    /**
     State value that will be echoed after authentication
     in order to check that the response is from your request and not other.

     By default a random value is used.

     - parameter state: a state value to send with the auth request

     - returns: the same WebAuth instance to allow method chaining
     */
    func state(_ state: String) -> Self

    /**
     Send additional parameters for authentication.

     - parameter parameters: additional auth parameters

     - returns: the same WebAuth instance to allow method chaining
     */
    func parameters(_ parameters: [String: String]) -> Self

    /// Specify a custom redirect url to be used
    ///
    /// - Parameter redirectURL: custom redirect url
    /// - Returns: the same WebAuth instance to allow method chaining
    func redirectURL(_ redirectURL: URL) -> Self

    /// Add `nonce` parameter for ID Token validation
    ///
    /// - Parameter nonce: nonce string
    /// - Returns: the same WebAuth instance to allow method chaining
    func nonce(_ nonce: String) -> Self

    ///  Audience name of the API that your application will call using the `access_token` returned after Auth.
    ///  This value must match the one defined in Auth0 Dashboard [APIs Section](https://manage.auth0.com/#/apis)
    ///
    /// - Parameter audience: an audience value like: `https://someapi.com/api`
    /// - Returns: the same WebAuth instance to allow method chaining
    func audience(_ audience: String) -> Self

    /// Specify a custom issuer for ID Token validation.
    /// This value will be used instead of the Auth0 domain.
    ///
    /// - Parameter issuer: custom issuer value like: `https://example.com/`
    /// - Returns: the same WebAuth instance to allow method chaining
    func issuer(_ issuer: String) -> Self

    /// Add a leeway amount for ID Token validation.
    /// This value represents the clock skew for the validation of date claims e.g. `exp`.
    ///
    /// - Parameter leeway: number of milliseconds. Defaults to `60000` (1 minute).
    /// - Returns: the same WebAuth instance to allow method chaining
    func leeway(_ leeway: Int) -> Self

    /// Add `max_age` parameter for authentication, only when response type `.idToken` is specified.
    /// Sending this parameter will require the presence of the `auth_time` claim in the ID Token.
    ///
    /// - Parameter maxAge: number of milliseconds
    /// - Returns: the same WebAuth instance to allow method chaining
    func maxAge(_ maxAge: Int) -> Self

    /**
     Disable Single Sign On (SSO) on iOS 13+ and macOS.
     Has no effect on older versions of iOS.

     - returns: the same WebAuth instance to allow method chaining
     */
    func useEphemeralSession() -> Self

    /// Specify an invitation URL to join an organization.
    ///
    /// - Parameter invitationURL: organization invitation URL
    /// - Returns: the same WebAuth instance to allow method chaining
    func invitationURL(_ invitationURL: URL) -> Self

    /// Specify an organization Id to log in to.
    ///
    /// - Parameter organization: organization Id
    /// - Returns: the same WebAuth instance to allow method chaining
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
     and it's corresponding callback with be called with a failure result of `AuthenticationError.userCancelled`.

     - Parameter callback: callback called with the result of the WebAuth flow.
     */
    func start(_ callback: @escaping (WebAuthResult<Credentials>) -> Void)

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
     and the subscription will complete with a failure result of `AuthenticationError.userCancelled`.

     - Returns: a type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func publisher() -> AnyPublisher<Credentials, WebAuthError>

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - seeAlso: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession { print($0) }
     ```

     Remove Auth0 session and remove the IdP session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - parameter federated: `Bool` to remove the IdP session. Defaults to `false`.
     - parameter callback: callback called with bool outcome of the call.
     */
    func clearSession(federated: Bool, callback: @escaping (Bool) -> Void)

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - seeAlso: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession()
         .sink(receiveValue: { print($0) })
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
     - Returns: a type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func clearSession(federated: Bool) -> AnyPublisher<Bool, Never>
}

// MARK: - Combine

extension WebAuth {

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - seeAlso: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession { print($0) }
     ```

     Remove Auth0 session and remove the IdP session:

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - Parameter federated: `Bool` to remove the IdP session. Defaults to `false`.
     - Parameter callback: callback called with bool outcome of the call.
     */
    public func clearSession(federated: Bool = false, callback: @escaping (Bool) -> Void) {
        self.clearSession(federated: federated, callback: callback)
    }

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - seeAlso: [Auth0 Logout docs](https://auth0.com/docs/login/logout)

     You will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

     ```
     Auth0
         .webAuth()
         .clearSession()
         .sink(receiveValue: { print($0) })
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
     - Returns: a type-erased publisher.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    public func clearSession(federated: Bool = false) -> AnyPublisher<Bool, Never> {
        return self.clearSession(federated: federated)
    }

}
#endif
