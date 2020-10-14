// NativeAuth.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
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

#if WEB_AUTH_PLATFORM
/**
 The NativeAuthCredentials struct defines the data requirements necessary to be returned
 from a successul authentication with an IdP SDK as part of the NativeAuthTransaction process.
 */
public struct NativeAuthCredentials {
    /// Access token returned by the IdP SDK
    let token: String
    /// Any extra attributes of the IdP that may be necessary during Auth with Auth0.
    let extras: [String: Any]

    /**
     Creates a new instance of `NativeAuthCredentials`
     
     - parameter token: IdP access token that will be used to authenticate with Auth0
     - parameter extras: Any extra attributes returned by the IdP.
    */
    public init(token: String, extras: [String: Any] = [:]) {
        self.token = token
        self.extras = extras
    }
}

/**
 Represent a Auth transaction where the user first authenticates with a third party Identity Provider (IdP) and then tries to perform Auth with Auth0.
 This is usually used when a Social connection has a native SDK, e.g. Facebook, and for usability or need to call the IdP API the SDK should be used to login.

 When implemeting this protocol you only need to take care of the IdP authentication and yield it's results so the Auth0 part of the flow will be taken care of for you
 
 To accomplish this the results of the IdP authentication should be send using the callback received when the method `func auth(callback: @escaping Callback) -> ()` is called.

 - important: Auth0 only support this for Facebook, Google and Twitter connections.
 */
public protocol NativeAuthTransaction: AuthTransaction {

    /// Scope sent to auth0 to login after the native auth, e.g.: openid
    var scope: String { get }
    /// Connection name registered in Auth0 used to authenticate with the native auth access_token
    var connection: String { get }
    /// Additional authentication parameters sent to Auth0 to perform the final auth
    var parameters: [String: Any] { get }
    /// Authenticaton object to perform the Auth0 social auth
    var authentication: Authentication { get }

    /// Callback where the result of the native authentication is sent
    typealias Callback = (Result<NativeAuthCredentials>) -> Void

    /**
     Starts the native Auth flow using the IdP SDK and once completed it will notify the result using the callback.

     On sucesss the IdP access token, and any parameter needed by Auth0 to authenticate, should be used to create a `NativeAuthCredentials`.

     ```
     let credetials = NativeAuthCredentials(token: "{IdP Token}", extras: [:])
     let result = Auth0.Result.success(result: credentials)
     ```
     - parameter callback: callback with the IdP credentials on success or the cause of the error.
     */
    func auth(callback: @escaping Callback)

    /**
     Starts the Auth transaction by trying to authenticate the user with the IdP SDK first,
     then on success it will try to auth with Auth0 using /oauth/access_token sending at least the IdP access_token.

     If Auth0 needs more parameters in order to authenticate a given IdP, they must be added in the `extra` attribute of `NativeAuthCredentials`

     - parameter callback: closure that will notify with the result of the Auth transaction. On success it will yield the Auth0 credentilas of the user otherwise it will yield the cause of the failure.
     - important: Only one `AuthTransaction` can be active at a given time, if there is a pending one (OAuth or Native) it will be cancelled and replaced by the new one.
     */
    func start(callback: @escaping (Result<Credentials>) -> Void)
}

/**
 Extension to handle Auth with Auth0 via /oauth/access_token endpoint
 */
public extension NativeAuthTransaction {

    /// For native authentication, this attribute does not matter at all. It's only used for OAuth 2.0 flows using /authorize
    var state: String? {
        return self.connection
    }

    /**
     Starts the Auth transaction by trying to authenticate the user with the IdP SDK first, 
     then on success it will try to auth with Auth0 using /oauth/access_token sending at least the IdP access_token.
     
     If Auth0 needs more parameters in order to authenticate a given IdP, they must be added in the `extra` attribute of `NativeAuthCredentials`

     - parameter callback: closure that will notify with the result of the Auth transaction. On success it will yield the Auth0 credentilas of the user otherwise it will yield the cause of the failure.
     - important: Only one `AuthTransaction` can be active at a given time, if there is a pending one (OAuth or Native) it will be cancelled and replaced by the new one.
     */
    func start(callback: @escaping (Result<Credentials>) -> Void) {
        TransactionStore.shared.store(self)
        self.auth { result in
            switch result {
            case .success(let credentials):
                var parameters: [String: Any] = self.parameters
                credentials.extras.forEach { parameters[$0] = $1 }
                self.authentication.loginSocial(token: credentials.token, connection: self.connection, scope: self.scope, parameters: parameters)
                    .start(callback)
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
    }
}
#endif
