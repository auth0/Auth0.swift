// Authentication.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// swiftlint:disable file_length

import Foundation

public typealias DatabaseUser = (email: String, username: String?, verified: Bool)

/**
 Auth endpoints of Auth0
 - seeAlso: [Auth0 Auth API docs](https://auth0.com/docs/api/authentication)
 */
public protocol Authentication: Trackable, Loggable {
    var clientId: String { get }
    var url: URL { get }

    /**
    Logs in a user using an email and an OTP code received via email (last part of the passwordless login flow)

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(email: "support@auth0.com", code: "123456")
       .start { result in
           switch result {
           case .success(let credentials):
               print(credentials)
           case .failure(let error):
               print(error)
           }
       }
    ```

    You can also specify audience, scope, and additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(email: "support@auth0.com",
            code: "123456",
            audience: "https://myapi.com/api",
            scope: "openid email",
            parameters: ["state": "a random state"])
       .start { print($0) }
    ```

    When result is `.success`, its associated value will be a`Credentials` object containing at least an `access_token` (depending on the scopes used to authenticate)

    - parameter email:             email the user used to start the passwordless login flow
    - parameter code:              one time password (OTP) code the user received via email
    - parameter audience:          API Identifier that the client is requesting access to. Default is `nil`
    - parameter scope:             scope value requested when authenticating the user. Default is `openid`
    - parameter parameters:        additional parameters that are optionally sent with the authentication request

    - returns: authentication request that will yield Auth0 User Credentials
    - seeAlso: Credentials
    - requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
    */
    func login(email username: String, code otp: String, audience: String?, scope: String?, parameters: [String: Any]) -> Request<Credentials, AuthenticationError>

    /**
    Logs in a user using a phone number and an OTP code received via sms (last part of the passwordless login flow)

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(phoneNumber: "+4599134762367", code: "123456")
       .start { result in
           switch result {
           case .success(let credentials):
               print(credentials)
           case .failure(let error):
               print(error)
           }
       }
    ```

    You can also specify audience, scope, and additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(phoneNumber: "+4599134762367",
            code: "123456",
            audience: "https://myapi.com/api",
            scope: "openid email",
            parameters: ["state": "a random state"])
       .start { print($0) }
    ```

    When result is `.success`, its associated value will be a`Credentials` object containing at least an `access_token` (depending on the scopes used to authenticate)

    - parameter phoneNumber:       phone number the user used to start the passwordless login flow
    - parameter code:              one time password (OTP) code the user received via sms
    - parameter audience:          API Identifier that the client is requesting access to. Default is `nil`
    - parameter scope:             scope value requested when authenticating the user. Default is `openid`
    - parameter parameters:        additional parameters that are optionally sent with the authentication request

    - returns: authentication request that will yield Auth0 User Credentials
    - seeAlso: Credentials
    - requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
    */
    func login(phoneNumber username: String, code otp: String, audience: String?, scope: String?, parameters: [String: Any]) -> Request<Credentials, AuthenticationError>

    /**
     Logs in an user using email|username and password using a Database and Passwordless connection

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .login(usernameOrEmail: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication")
        .start { result in
            switch result {
            case .Success(let credentials):
                print(credentials)
            case .Failure(let error):
                print(error)
            }
        }
     ```

     you can also specify scope and additional parameters

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .login(usernameOrEmail: "support@auth0.com", password:  "a secret password", connection: "Username-Password-Authentication", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     for passwordless connections

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .login(usernameOrEmail: "+4599134762367", password: "123456", connection: "sms", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     Also some enterprise connections, like Active Directory (AD), allows authentication using username/password without using the web flow.

     When result is `.success`, its associated value will be a`Credentials` object containing at least an `access_token` (depending on the scopes used to authenticate)

     - parameter usernameOrEmail:   username or email used of the user to authenticate, e.g. in email in Database connections or phone number for SMS connections.
     - parameter password:          password of the user or one time password (OTP) for passwordless connection users
     - parameter multifactorCode:   multifactor code if the user has enrolled one. e.g. Guardian. By default is `nil` and no code is sent.
     - parameter connection:        name of any of your configured database or passwordless connections
     - parameter scope:             scope value requested when authenticating the user. Default is 'openid'
     - parameter parameters:        additional parameters that are optionally sent with the authentication request

     - returns: authentication request that will yield Auth0 User Credentials
     - seeAlso: Credentials
     - warning: this method is deprecated in favor of `login(usernameOrEmail username:, password:, realm:, audience:, scope:)` for Database connections. For Passwordless connections use `login(email:, code:, audience:, scope:, parameters:)` or `login(phoneNumber:, code:, audience:, scope:, parameters:)` instead.
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/ro`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    @available(*, deprecated, message: "see login(usernameOrEmail username:, password:, realm:, audience:, scope:)")
    // swiftlint:disable:next function_parameter_count
    func login(usernameOrEmail username: String, password: String, multifactorCode: String?, connection: String, scope: String, parameters: [String: Any]) -> Request<Credentials, AuthenticationError>

    /**
     Login using username and password in a realm.

     ```
     Auth0
     .authentication(clientId: clientId, domain: "samples.auth0.com")
     .login(
         usernameOrEmail: "support@auth0.com",
         password: "a secret password",
         realm: "mydatabase")
     ```

     You can also specify audience and scope

     ```
     Auth0
     .authentication(clientId: clientId, domain: "samples.auth0.com")
     .login(
         usernameOrEmail: "support@auth0.com",
         password: "a secret password",
         realm: "mydatabase",
         audience: "https://myapi.com/api",
         scope: "openid profile")
     ```

     - parameter username:    username or email used of the user to authenticate
     - parameter password:    password of the user
     - parameter realm:       domain of the realm or connection name
     - parameter audience:    API Identifier that the client is requesting access to.
     - parameter scope:       scope value requested when authenticating the user.
     - parameter parameters:  additional parameters that are optionally sent with the authentication request

     - important: This only works if you have the OAuth 2.0 API Authorization flag on
     - returns: authentication request that will yield Auth0 User Credentials
     - requires: Grant `http://auth0.com/oauth/grant-type/password-realm`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    // swiftlint:disable:next function_parameter_count
    func login(usernameOrEmail username: String, password: String, realm: String, audience: String?, scope: String?, parameters: [String: Any]?) -> Request<Credentials, AuthenticationError>

    /**
     Login using One Time Password and MFA token.

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .login(withOTP: "123456", mfaToken: "mfa token value")
     }
     ```

     - parameter otp:       One time password supplied by MFA Authenticator
     - parameter mfaToken:  Token returned when authentication fails due to MFA requirement

     - requires: Grant `http://auth0.com/oauth/grant-type/mfa-otp`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func login(withOTP otp: String, mfaToken: String) -> Request<Credentials, AuthenticationError>

    /**
    Authenticate a user with their Sign In With Apple authorization code.

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(appleAuthorizationCode: authCode)
       .start { print($0) }
    ```

    and if you need to specify a scope or add additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(appleAuthorizationCode: authCode,
            fullName: credentials.fullName,
            scope: "openid profile email",
            audience: "https://myapi.com/api")
       .start { print($0) }
    ```

    - parameter authCode: Authorization Code retrieved from Apple Authorization
    - parameter fullName: The full name property returned with the Apple ID Credentials
    - parameter profile: Additional user profile data returned with the Apple ID Credentials
    - parameter scope: Requested scope value when authenticating the user. By default is `openid profile offline_access`
    - parameter audience: API Identifier that the client is requesting access to

    - returns: a request that will yield Auth0 user's credentials
    */
    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents?, profile: [String: Any]?, scope: String?, audience: String?) -> Request<Credentials, AuthenticationError>

    /**
    Authenticate a user with their Facebook session info access token and profile data.

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
       .start { print($0) }
    ```

    and if you need to specify a scope or audience

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(facebookSessionAccessToken: sessionAccessToken,
            scope: "openid profile email",
            audience: "https://myapi.com/api")
       .start { print($0) }
    ```

    - parameter sessionAccessToken: Session info access token retrieved from Facebook
    - parameter profile: The user profile returned by Facebook
    - parameter scope: Requested scope value when authenticating the user. By default is `openid profile offline_access`
    - parameter audience: API Identifier that the client is requesting access to

    - returns: a request that will yield Auth0 user's credentials
    */
    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], scope: String?, audience: String?) -> Request<Credentials, AuthenticationError>

    /**
     Login using username and password in the default directory
     
     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginDefaultDirectory(
            withUsername: "support@auth0.com",
            password: "a secret password")
     ```
     
     You can also specify audience and scope
     
     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginDefaultDirectory(
            withUsername: "support@auth0.com",
            password: "a secret password",
            audience: "https://myapi.com/api",
            scope: "openid profile")
     ```
     
     - parameter username:    username or email used of the user to authenticate
     - parameter password:    password of the user
     - parameter audience:    API Identifier that the client is requesting access to.
     - parameter scope:       scope value requested when authenticating the user.
     - parameter parameters:  additional parameters that are optionally sent with the authentication request
     
     - important: This only works if you have the OAuth 2.0 API Authorization flag on
     - returns: authentication request that will yield Auth0 User Credentials
     */
    func loginDefaultDirectory(withUsername username: String, password: String, audience: String?, scope: String?, parameters: [String: Any]?) -> Request<Credentials, AuthenticationError>

    /**
     Creates a user in a Database connection

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .createUser(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     you can also add additional metadata when creating the user

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .createUser(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication", userMetadata: ["first_name": "support"])
        .start { print($0) }
     ```

     and if the database connection requires a username

     ```
     Auth0
        .authentication(clientId, domain: "samples.auth0.com")
        .createUser(email: "support@auth0.com", username: "support", password: "a secret password", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     - parameter email:             email of the user to create
     - parameter username:          username of the user if the connection requires username. By default is 'nil'
     - parameter password:          password for the new user
     - parameter connection:        name where the user will be created (Database connection)
     - parameter userMetadata:      additional userMetadata parameters that will be added to the newly created user.
     - parameter rootAttributes:    root attributes that will be added to the newly created user. See https://auth0.com/docs/api/authentication#signup for supported attributes. Will not overwrite existing parameters.
     
     - returns: request that will yield a created database user (just email, username and email verified flag)
     */
    // swiftlint:disable:next function_parameter_count
    func createUser(email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, rootAttributes: [String: Any]?) -> Request<DatabaseUser, AuthenticationError>

    /**
     Resets a Database user password

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .resetPassword(email: "support@auth0.com", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     - parameter email:      email of the database user
     - parameter connection: name of the Database connection

     - returns: request to reset password
     */
    func resetPassword(email: String, connection: String) -> Request<Void, AuthenticationError>

    /**
     Creates a database user and then authenticates the user against Auth0.

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .signUp(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     you can also add additional attributes when creating the user

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .signUp(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication", userMetadata: ["first_name": "support"])
        .start { print($0) }
     ```

     and if the database connection requires a username

     ```
     Auth0
     .authentication(clientId: clientId, domain: "samples.auth0.com")
     .signUp(email: "support@auth0.com", username: "support", password: "a secret password", connection: "Username-Password-Authentication")
     .start { print($0) }
     ```

     or specifying the scope and parameters used for authentication

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .signUp(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     - parameter email:        email of the new user
     - parameter username:     username of the user if connections requires username. By default is 'nil'
     - parameter password:     password for the new user
     - parameter connection:   name of the Database connection where the user will be created
     - parameter userMetadata: additional userMetadata values added when creating the user
     - parameter scope:        requested scope value when authenticating the user. By default is 'openid'
     - parameter parameters:   additional parameters sent during authentication

     - returns: an authentication request that will yield Auth0 user credentials after creating the user.
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/ro`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    @available(*, deprecated, message: "use createUser(email:, username:, password:, connection:, userMetadata:) and then login(usernameOrEmail username:, password:, realm:, audience:, scope:)")
    // swiftlint:disable:next function_parameter_count
    func signUp(email: String, username: String?, password: String, connection: String, userMetadata: [String: Any]?, scope: String, parameters: [String: Any]) -> ConcatRequest<DatabaseUser, Credentials, AuthenticationError>

    /**
     Starts passwordless authentication by sending an email with a OTP code

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(email: "support@auth0.com")
        .start { print($0) }
     ```

     or if you have configured iOS Universal Links

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(email: "support@auth0.com", type: .iOSLink)
        .start { print($0) }
     ```

     - parameter email:      email where to send the code or link
     - parameter type:       type of passwordless authentication/ By default is code
     - parameter connection: name of the passwordless connection. By default is 'email'
     - parameter parameters: additional authentication parameters added for Web link. Ignored in other types

     - returns: a request
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/ro`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func startPasswordless(email: String, type: PasswordlessType, connection: String, parameters: [String: Any]) -> Request<Void, AuthenticationError>

    /**
     Starts passwordless authentication by sending an sms with an OTP code

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(phoneNumber: "support@auth0.com")
        .start { print($0) }
     ```

     or if you have configured iOS Universal Links

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(phoneNumber: "support@auth0.com", type: .iOSLink)
        .start { print($0) }
     ```

     - parameter phoneNumber:   phone number where to send the sms with code or link
     - parameter type:          type of passwordless authentication. By default is code
     - parameter connection:    name of the passwordless connection. By default is 'sms'

     - returns: a request
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/ro`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func startPasswordless(phoneNumber: String, type: PasswordlessType, connection: String) -> Request<Void, AuthenticationError>

    /**
     Returns token information by performing a request to the `/tokeninfo` endpoint.

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .tokenInfo(token: token)
        .start { print($0) }
     ```
     
     - parameter token: token obtained by authenticating the user
     - warning: this method is deprecated in favor of `userInfo(withAccessToken accessToken:)`
     - returns: a request that will yield token information
     */
    @available(*, deprecated, message: "see userInfo(withAccessToken accessToken:)")
    func tokenInfo(token: String) -> Request<Profile, AuthenticationError>

    /**
     Returns user information by performing a request to the `/userinfo` endpoint.

     ```
     Auth0
        .authentication(clientId, domain: "samples.auth0.com")
        .userInfo(token: token)
        .start { print($0) }
     ```

     - parameter token: token obtained by authenticating the user

     - returns: a request that will yield user information
     - warning: for OIDC-conformant clients please use `userInfo(withAccessToken accessToken:)`
     */
    func userInfo(token: String) -> Request<Profile, AuthenticationError>

    /**
     Returns OIDC standard claims information by performing a request
     to the `/userinfo` endpoint.

     ```
     Auth0
     .authentication(clientId, domain: "samples.auth0.com")
     .userInfo(withAccessToken: accessToken)
     .start { print($0) }
     ```

     - parameter accessToken: accessToken obtained by authenticating the user

     - returns: a request that will yield user information
     - important: This method should be used for OIDC Conformant clients.
     */
    func userInfo(withAccessToken accessToken: String) -> Request<UserInfo, AuthenticationError>

    /**
     Logs in a user using a social Identity Provider token. e.g. Facebook

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginSocial(token: fbToken, connection: "facebook")
        .start { print($0) }
     ```

     and if you need to specify a scope or add additional parameters

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginSocial(token: fbToken, connection: "facebook", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     - parameter token:      token obtained from a social IdP
     - parameter connection: name of the social connection. Only works with 'google-oauth2', 'facebook' and 'twitter'
     - parameter scope:      requested scope value when authenticating the user. By default is 'openid'
     - parameter parameters: additional parameters sent during authentication

     - returns: a request that will yield Auth0 user's credentials
     - warning: disabled for OIDC-conformant clients, an alternative will be added in a future release
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/access_token`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func loginSocial(token: String, connection: String, scope: String, parameters: [String: Any]) -> Request<Credentials, AuthenticationError>

    /**
     Perform a OAuth2 token request against Auth0.

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .tokenExchange(withParameters: ["key": "value"])
        .start { print($0) }
     ```

     - parameter parameters: request parameters

     - returns: a request that will yield Auth0 user's credentials
     - seeAlso: exchangeCode(codeVerifier:, redirectURI:) for PKCE
     */
    func tokenExchange(withParameters parameters: [String: Any]) -> Request<Credentials, AuthenticationError>

    /**
     Performs the last step of Proof Key for Code Exchange [RFC 7636](https://tools.ietf.org/html/rfc7636).

     This will request User's token using the code and it's verifier after a request to `/oauth/authorize`

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .tokenExchange(withCode: "a code", codeVerifier: "code verifier", redirectURI: "https://samples.auth0.com/callback")
        .start { print($0) }
     ```

     - parameter code:         code returned after an `/oauth/authorize` request
     - parameter codeVerifier: verifier used to generate the challenge sent in `/oauth/authorize` request
     - parameter redirectURI:  redirect uri sent in `/oauth/authorize` request

     - returns: a request that will yield Auth0 user's credentials
     - seeAlso: https://tools.ietf.org/html/rfc7636
     */
    func tokenExchange(withCode code: String, codeVerifier: String, redirectURI: String) -> Request<Credentials, AuthenticationError>

    /**
    Authenticate a user with their Sign In With Apple authorization code.

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .tokenExchange(withAppleAuthorizationCode: authCode)
       .start { print($0) }
    ```

    and if you need to specify a scope or add additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .tokenExchange(withAppleAuthorizationCode: authCode,
           scope: "openid profile email",
           audience: "https://myapi.com/api",
           fullName: credentials.fullName)
       .start { print($0) }
    ```

    - parameter authCode: Authorization Code retrieved from Apple Authorization
    - parameter scope: Requested scope value when authenticating the user. By default is `openid profile offline_access`
    - parameter audience: API Identifier that the client is requesting access to
    - parameter fullName: The full name property returned with the Apple ID Credentials

    - returns: a request that will yield Auth0 user's credentials
    - warning: this method is deprecated in favor of `login(appleAuthorizationCode authorizationCode:, fullName:, scope:, audience:)`
    */
    @available(*, deprecated, message: "see login(appleAuthorizationCode authorizationCode:, fullName:, scope:, audience:)")
    func tokenExchange(withAppleAuthorizationCode authCode: String, scope: String?, audience: String?, fullName: PersonNameComponents?) -> Request<Credentials, AuthenticationError>

    /**
     Renew user's credentials with a refresh_token grant for `/oauth/token`
     If you are not using OAuth 2.0 API Authorization please use `delegation(parameters:)`
     - parameter refreshToken: the client's refresh token
     - parameter scope: scopes to request for the new tokens. By default is nil which will ask for the same ones requested during Auth.
     - important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
     - returns: a request that will yield Auth0 user's credentials
     */
    func renew(withRefreshToken refreshToken: String, scope: String?) -> Request<Credentials, AuthenticationError>

    /**
     Revoke a user's refresh_token with a call to `/oauth/revoke`
     
     ```
     Auth0
     .authentication(clientId: clientId, domain: "samples.auth0.com")
     .revoke(refreshToken: refreshToken)
     .start { print($0) }
     ```

     - parameter refreshToken: the client's refresh token
     - returns: a request
     */
    func revoke(refreshToken: String) -> Request<Void, AuthenticationError>

    /**
     Calls delegation endpoint with the given parameters.
     The only parameters it adds by default are `grant_type` and `client_id`.
     - parameter parametes: dictionary with delegation parameters to send in the request.
     - returns: a request that will yield the result of delegation
    */
    func delegation(withParameters parameters: [String: Any]) -> Request<[String: Any], AuthenticationError>

    /**
    Returns JSON Web Key Set (JWKS) information by performing a request to the `/.well-known/jwks.json` endpoint.

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .jwks()
       .start { print($0) }
    ```
    
    - returns: a request that will yield JWKS information
    */
    func jwks() -> Request<JWKS, AuthenticationError>

#if WEB_AUTH_PLATFORM
    /**
     Creates a new WebAuth request to authenticate using Safari browser and OAuth authorize flow.

     With the connection name Auth0 will redirect to the associated IdP login page to authenticate
     
     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .webAuth(withConnection: "facebook")
        .start { print($0) }
     ```

     If you need to show your Auth0 account login page just create the WebAuth object directly

     ```
     Auth0
        .webAuth(clientId: clientId, domain: "samples.auth0.com")
        .start { print($0) }
     ```

     - parameter connection: name of the connection to use
     - returns: a newly created WebAuth object.
     */
    func webAuth(withConnection connection: String) -> WebAuth
#endif
}

/**
 Types of passwordless authentication

 - Code:        Simple OTP code sent by email or sms
 - WebLink:     Regular Web HTTP link (Web only, uses redirect)
 - iOSLink:     iOS 9 Universal Link
 - AndroidLink: Android App Link
 */
public enum PasswordlessType: String {
    case Code = "code"
    case WebLink = "link"
    case iOSLink = "link_ios"
    case AndroidLink = "link_android"
}

public extension Authentication {

    /**
    Logs in a user using an email and an OTP code received via email (last part of the passwordless login flow)

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(email: "support@auth0.com", code: "123456")
       .start { result in
           switch result {
           case .success(let credentials):
               print(credentials)
           case .failure(let error):
               print(error)
           }
       }
    ```

    You can also specify audience, scope, and additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(email: "support@auth0.com",
            code: "123456",
            audience: "https://myapi.com/api",
            scope: "openid email",
            parameters: ["state": "a random state"])
       .start { print($0) }
    ```

    When result is `.success`, its associated value will be a`Credentials` object containing at least an `access_token` (depending on the scopes used to authenticate)

    - parameter email:             email the user used to start the passwordless login flow
    - parameter code:              one time password (OTP) code the user received via email
    - parameter audience:          API Identifier that the client is requesting access to. Default is `nil`
    - parameter scope:             scope value requested when authenticating the user. Default is `openid`
    - parameter parameters:        additional parameters that are optionally sent with the authentication request

    - returns: authentication request that will yield Auth0 User Credentials
    - seeAlso: Credentials
    - requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
    */
    func login(email username: String, code otp: String, audience: String? = nil, scope: String? = "openid", parameters: [String: Any] = [:]) -> Request<Credentials, AuthenticationError> {
        return self.login(email: username, code: otp, audience: audience, scope: scope, parameters: parameters)
    }

    /**
    Logs in a user using a phone number and an OTP code received via sms (last part of the passwordless login flow)

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(phoneNumber: "+4599134762367", code: "123456")
       .start { result in
           switch result {
           case .success(let credentials):
               print(credentials)
           case .failure(let error):
               print(error)
           }
       }
    ```

    You can also specify audience, scope, and additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(phoneNumber: "+4599134762367",
            code: "123456",
            audience: "https://myapi.com/api",
            scope: "openid email",
            parameters: ["state": "a random state"])
       .start { print($0) }
    ```

    When result is `.success`, its associated value will be a`Credentials` object containing at least an `access_token` (depending on the scopes used to authenticate)

    - parameter phoneNumber:       phone number the user used to start the passwordless login flow
    - parameter code:              one time password (OTP) code the user received via sms
    - parameter audience:          API Identifier that the client is requesting access to. Default is `nil`
    - parameter scope:             scope value requested when authenticating the user. Default is `openid`
    - parameter parameters:        additional parameters that are optionally sent with the authentication request

    - returns: authentication request that will yield Auth0 User Credentials
    - seeAlso: Credentials
    - requires: Passwordless OTP Grant `http://auth0.com/oauth/grant-type/passwordless/otp`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
    */
    func login(phoneNumber username: String, code otp: String, audience: String? = nil, scope: String? = "openid", parameters: [String: Any] = [:]) -> Request<Credentials, AuthenticationError> {
        return self.login(phoneNumber: username, code: otp, audience: audience, scope: scope, parameters: parameters)
    }

    /**
     Logs in an user using email|username and password using a Database and Passwordless connection

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .login(usernameOrEmail: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication")
        .start { result in
            switch result {
            case .Success(let credentials):
                print(credentials)
            case .Failure(let error):
                print(error)
            }
        }
     ```

     you can also specify scope and additional parameters

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .login(usernameOrEmail: "support@auth0.com", password:  "a secret password", connection: "Username-Password-Authentication", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     for passwordless connections

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .login(usernameOrEmail: "+4599134762367", password: "123456", connection: "sms", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     Also some enterprise connections, like Active Directory (AD), allows authentication using username/password without using the web flow.

     When result is `.success`, its associated value will be a`Credentials` object containing at least an `access_token` (depending on the scopes used to authenticate)

     - parameter usernameOrEmail:   username or email used of the user to authenticate, e.g. in email in Database connections or phone number for SMS connections.
     - parameter password:          password of the user or one time password (OTP) for passwordless connection users
     - parameter multifactorCode:   multifactor code if the user has enrolled one. e.g. Guardian. By default is `nil` and no code is sent.
     - parameter connection:        name of any of your configured database or passwordless connections
     - parameter scope:             scope value requested when authenticating the user. Default is 'openid'
     - parameter parameters:        additional parameters that are optionally sent with the authentication request

     - returns: authentication request that will yield Auth0 User Credentials
     - seeAlso: Credentials
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/ro`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func login(usernameOrEmail username: String, password: String, multifactorCode: String? = nil, connection: String, scope: String = "openid", parameters: [String: Any] = [:]) -> Request<Credentials, AuthenticationError> {
        return self.login(usernameOrEmail: username, password: password, multifactorCode: multifactorCode, connection: connection, scope: scope, parameters: parameters)
    }

    /**
     Login using username and password in a realm.

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(
             usernameOrEmail: "support@auth0.com",
             password: "a secret password",
             realm: "mydatabase")
     ```

     You can also specify audience and scope

     ```
     Auth0
         .authentication(clientId: clientId, domain: "samples.auth0.com")
         .login(
             usernameOrEmail: "support@auth0.com",
             password: "a secret password",
             realm: "mydatabase",
             audience: "https://myapi.com/api",
             scope: "openid profile")
     ```

     - parameter username: username or email used of the user to authenticate
     - parameter password: password of the user
     - parameter realm: domain realm or connection name
     - parameter audience: API Identifier that the client is requesting access to.
     - parameter scope: scope value requested when authenticating the user.
     - parameter parameters: additional parameters that are optionally sent with the authentication request
     - Returns: authentication request that will yield Auth0 User Credentials
     - requires: Grant `http://auth0.com/oauth/grant-type/password-realm`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func login(usernameOrEmail username: String, password: String, realm: String, audience: String? = nil, scope: String? = nil, parameters: [String: Any]? = nil) -> Request<Credentials, AuthenticationError> {
        return self.login(usernameOrEmail: username, password: password, realm: realm, audience: audience, scope: scope, parameters: parameters)
    }

    /**
    Authenticate a user with their Sign In With Apple authorization code.

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(appleAuthorizationCode: authCode)
       .start { print($0) }
    ```

    and if you need to specify a scope or add additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(appleAuthorizationCode: authCode,
            fullName: credentials.fullName,
            scope: "openid profile email",
            audience: "https://myapi.com/api")
       .start { print($0) }
    ```

    - parameter authCode: Authorization Code retrieved from Apple Authorization
    - parameter fullName: The full name property returned with the Apple ID Credentials
    - parameter profile: Additional user profile data returned with the Apple ID Credentials
    - parameter scope: Requested scope value when authenticating the user. By default is `openid profile offline_access`
    - parameter audience: API Identifier that the client is requesting access to

    - returns: a request that will yield Auth0 user's credentials
    */
    func login(appleAuthorizationCode authorizationCode: String, fullName: PersonNameComponents? = nil, profile: [String: Any]? = nil, scope: String? = "openid profile offline_access", audience: String? = nil) -> Request<Credentials, AuthenticationError> {
        return self.login(appleAuthorizationCode: authorizationCode, fullName: fullName, profile: profile, scope: scope, audience: audience)
    }

    /**
    Authenticate a user with their Facebook session info access token and profile data.

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(facebookSessionAccessToken: sessionAccessToken, profile: profile)
       .start { print($0) }
    ```

    and if you need to specify a scope or audience

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .login(facebookSessionAccessToken: sessionAccessToken,
            scope: "openid profile email",
            audience: "https://myapi.com/api")
       .start { print($0) }
    ```

    - parameter sessionAccessToken: Session info access token retrieved from Facebook
    - parameter profile: The user profile returned by Facebook
    - parameter scope: Requested scope value when authenticating the user. By default is `openid profile offline_access`
    - parameter audience: API Identifier that the client is requesting access to

    - returns: a request that will yield Auth0 user's credentials
    */
    func login(facebookSessionAccessToken sessionAccessToken: String, profile: [String: Any], scope: String? = "openid profile offline_access", audience: String? = nil) -> Request<Credentials, AuthenticationError> {
        return self.login(facebookSessionAccessToken: sessionAccessToken, profile: profile, scope: scope, audience: audience)
    }

    /**
     Login using username and password in the default directory
     
     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginDefaultDirectory(
            withUsername: "support@auth0.com",
            password: "a secret password")
     ```
     
     You can also specify audience and scope
     
     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginDefaultDirectory(
            withUsername: "support@auth0.com",
            password: "a secret password",
            audience: "https://myapi.com/api",
            scope: "openid profile")
     ```
     
     - parameter username:    username or email used of the user to authenticate
     - parameter password:    password of the user
     - parameter audience:    API Identifier that the client is requesting access to.
     - parameter scope:       scope value requested when authenticating the user.
     - parameter parameters:  additional parameters that are optionally sent with the authentication request
     
     - important: This only works if you have the OAuth 2.0 API Authorization flag on
     - returns: authentication request that will yield Auth0 User Credentials
     */
    func loginDefaultDirectory(withUsername username: String, password: String, audience: String? = nil, scope: String? = nil, parameters: [String: Any]? = nil) -> Request<Credentials, AuthenticationError> {
        return self.loginDefaultDirectory(withUsername: username, password: password, audience: audience, scope: scope, parameters: parameters)
    }

    /**
     Creates a user in a Database connection

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .createUser(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     you can also add additional attributes when creating the user

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .createUser(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication", userMetadata: ["first_name": "support"])
        .start { print($0) }
     ```

     and if the database connection requires a username

     ```
     Auth0
        .authentication(clientId, domain: "samples.auth0.com")
        .createUser(email: "support@auth0.com", username: "support", password: "a secret password", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     - parameter email:             email of the user to create
     - parameter username:          username of the user if the connection requires username. By default is 'nil'
     - parameter password:          password for the new user
     - parameter connection:        name where the user will be created (Database connection)
     - parameter userMetadata:      additional userMetadata parameters that will be added to the newly created user.
     - parameter rootAttributes:    root attributes that will be added to the newly created user. See https://auth0.com/docs/api/authentication#signup for supported attributes. Will not overwrite existing parameters.

     - returns: request that will yield a created database user (just email, username and email verified flag)
     */
    func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil, rootAttributes: [String: Any]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        return self.createUser(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata, rootAttributes: rootAttributes)
    }

    /**
     Creates a user in a Database connection
     
     - parameter email:             email of the user to create
     - parameter username:          username of the user if the connection requires username. By default is 'nil'
     - parameter password:          password for the new user
     - parameter connection:        name where the user will be created (Database connection)
     - parameter userMetadata:      additional userMetadata parameters that will be added to the newly created user.
    
     - returns: request that will yield a created database user (just email, username and email verified flag)
     */
    func createUser(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil) -> Request<DatabaseUser, AuthenticationError> {
        return self.createUser(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata, rootAttributes: nil)
    }

    /**
     Creates a database user and then authenticates the user against Auth0.

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .signUp(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     you can also add additional attributes when creating the user

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .signUp(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication", userMetadata: ["first_name": "support"])
        .start { print($0) }
     ```

     and if the database connection requires a username

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .signUp(email: "support@auth0.com", username: "support", password: "a secret password", connection: "Username-Password-Authentication")
        .start { print($0) }
     ```

     or specifying the scope and parameters used for authentication

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .signUp(email: "support@auth0.com", password: "a secret password", connection: "Username-Password-Authentication", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     - parameter email:        email of the new user
     - parameter username:     username of the user if connections requires username. By default is 'nil'
     - parameter password:     password for the new user
     - parameter connection:   name of the Database connection where the user will be created
     - parameter userMetadata: additional userMetadata values added when creating the user
     - parameter scope:        requested scope value when authenticating the user. By default is 'openid'
     - parameter parameters:   additional parameters sent during authentication

     - returns: an authentication request that will yield Auth0 user credentials after creating the user.
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/ro`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func signUp(email: String, username: String? = nil, password: String, connection: String, userMetadata: [String: Any]? = nil, scope: String = "openid", parameters: [String: Any] = [:]) -> ConcatRequest<DatabaseUser, Credentials, AuthenticationError> {
        return self.signUp(email: email, username: username, password: password, connection: connection, userMetadata: userMetadata, scope: scope, parameters: parameters)
    }

    /**
     Starts passwordless authentication by sending an email with a OTP code

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(email: "support@auth0.com")
        .start { print($0) }
     ```

     or if you have configured iOS Universal Links

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(email: "support@auth0.com", type: .iOSLink)
        .start { print($0) }
     ```

     - parameter email:      email where to send the code or link
     - parameter type:       type of passwordless authentication/ By default is code
     - parameter connection: name of the passwordless connection. By default is 'email'
     - parameter parameters: additional authentication parameters added for Web link. Ignored in other types

     - returns: a request
     */
    func startPasswordless(email: String, type: PasswordlessType = .Code, connection: String = "email", parameters: [String: Any] = [:]) -> Request<Void, AuthenticationError> {
        return self.startPasswordless(email: email, type: type, connection: connection, parameters: parameters)
    }

    /**
     Starts passwordless authentication by sending an sms with an OTP code

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(phoneNumber: "support@auth0.com")
        .start { print($0) }
     ```

     or if you have configured iOS Universal Links

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .startPasswordless(phoneNumber: "support@auth0.com", type: .iOSLink)
        .start { print($0) }
     ```
     - parameter phoneNumber:   phone number where to send the sms with code or link
     - parameter type:          type of passwordless authentication. By default is code
     - parameter connection:    name of the passwordless connection. By default is 'sms'

     - returns: a request
     */
    func startPasswordless(phoneNumber: String, type: PasswordlessType = .Code, connection: String = "sms") -> Request<Void, AuthenticationError> {
        return self.startPasswordless(phoneNumber: phoneNumber, type: type, connection: connection)
    }

    /**
     Logs in a user using a social Identity Provider token. e.g. Facebook

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginSocial(token: fbToken, connection: "facebook")
        .start { print($0) }
     ```

     and if you need to specify a scope or add additional parameters

     ```
     Auth0
        .authentication(clientId: clientId, domain: "samples.auth0.com")
        .loginSocial(token: fbToken, connection: "facebook", scope: "openid email", parameters: ["state": "a random state"])
        .start { print($0) }
     ```

     - parameter token:      token obtained from a social IdP
     - parameter connection: name of the social connection. Only works with 'google-oauth2', 'facebook' and 'twitter'
     - parameter scope:      requested scope value when authenticating the user. By default is 'openid'
     - parameter parameters: additional parameters sent during authentication

     - returns: a request that will yield Auth0 user's credentials
     - requires: Legacy Grant `http://auth0.com/oauth/legacy/grant-type/access_token`. Check [our documentation](https://auth0.com/docs/clients/client-grant-types) for more info and how to enable it.
     */
    func loginSocial(token: String, connection: String, scope: String = "openid", parameters: [String: Any] = [:]) -> Request<Credentials, AuthenticationError> {
        return self.loginSocial(token: token, connection: connection, scope: scope, parameters: parameters)
    }

    /**
     Renew user's credentials with a refresh_token grant for `/oauth/token`
     
     ```
     Auth0
        .renew(withRefreshToken: refreshToken, scope: "openid email read:users")
        .start { print($0) }
     ```

     or asking the same scopes requested when the refresh token was issued

     ```
     Auth0
        .renew(withRefreshToken: refreshToken)
        .start { print($0) }
     ```

     - precondition: if you are not using OAuth 2.0 API Authorization please use `delegation(parameters:)`

     - parameter refreshToken: the client's refresh token
     - parameter scope: scopes to request for the new tokens. By default is nil which will ask for the same ones requested during Auth.
     - important: This method only works for a refresh token obtained after auth with OAuth 2.0 API Authorization.
     - returns: a request that will yield Auth0 user's credentials
     */
    func renew(withRefreshToken refreshToken: String, scope: String? = nil) -> Request<Credentials, AuthenticationError> {
        return self.renew(withRefreshToken: refreshToken, scope: scope)
    }

    /**
    Authenticate a user with their Sign In With Apple authorization code.

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .tokenExchange(withAppleAuthorizationCode: authCode)
       .start { print($0) }
    ```

    and if you need to specify a scope or add additional parameters

    ```
    Auth0
       .authentication(clientId: clientId, domain: "samples.auth0.com")
       .tokenExchange(withAppleAuthorizationCode: authCode,
           scope: "openid profile email",
           audience: "https://myapi.com/api",
           fullName: credentials.fullName)
       .start { print($0) }
    ```

    - parameter authCode: Authorization Code retrieved from Apple Authorization
    - parameter scope: Requested scope value when authenticating the user. By default is `openid profile offline_access`
    - parameter audience: API Identifier that the client is requesting access to
    - parameter fullName: The full name property returned with the Apple ID Credentials

    - returns: a request that will yield Auth0 user's credentials
    */
    func tokenExchange(withAppleAuthorizationCode authCode: String, scope: String? = "openid profile offline_access", audience: String? = nil, fullName: PersonNameComponents? = nil) -> Request<Credentials, AuthenticationError> {
        return self.tokenExchange(withAppleAuthorizationCode: authCode, scope: scope, audience: audience, fullName: fullName)
    }

}
