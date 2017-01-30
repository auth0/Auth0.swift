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

import UIKit

/**
 The NativeAuthCredentials struct defines the data requirements necessary to be returned
 from a successul authentication with an IdP SDK as part of the NativeAuthTransaction process.
 */
public struct NativeAuthCredentials {
    /// The OAuth2 access token returned by the IdP SDK
    let token: String
    /// Any extras that may be necessary for certain Social IdP connections
    let extras: [String: Any]

    public init(token: String, extras: [String: Any]) {
        self.token = token
        self.extras = extras
    }
}

/**
 The NativeAuthTransaction expands on the AuthTransaction protocol to add additional functionality
 required for handling Native Authentication scenarios. You will need to implement this protocol's
 properties and methods to handle your Social IdP authentication transaction and yield `NativeAuthCredentials`
 to be handled by Auth0's `authentication().loginSocial(...)` yielding the Auth0 user's credentials.
 
 **Properties**

 `connection:` name of the social connection.

 `scope:`      requested scope value when authenticating the user.

 `parameters:` additional parameters sent during authentication.
 
 `delayed:`    callback that takes a `Result<NativeAuthCredentials>` to handle the outcome from the Social IdP authentication.

 **Methods**

 `func auth(callback: @escaping NativeAuthTransaction.Callback)`

 In this method you should deal with the Social IdP SDKssign in login process. Upon a successful
 authentication event, you should yield a `NativeAuthCredentials` `Result` to the `callback` containing
 the OAuth2 access token from the IdP and any extras that may be necessary for Auth0 to authenticate with
 the chosen IdP. If the authentication was not a success then yield an `Error` `Result`.
 

 `func cancel()`

 In this method you should deal with the cancellation of the IdP authentication, if your IdP SDK requires
 any extra steps to cancel this would be a good place to add them.

 `func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool`
 
 In this method you should handle the continuation of the IdP's authentication process that occurs once control
 is returned back to the application through the `AppDelegate`
 Typically this is a call to the IdP SDKs own handler.

 **Example**

 ```
 class FacebookNativeAuthTransaction: NativeAuthTransaction {

     var connection: String = "facebook"
     var scope: String = "openid"
     var parameters: [String : Any] = [:]
     var delayed: NativeAuthTransaction.Callback = { _ in }

     func auth(callback: @escaping NativeAuthTransaction.Callback) {
         LoginManager().logIn([.publicProfile]) { result in
             case .success(_, _, let token):
                 self.delayed(.success(result: NativeAuthCredentials(token: token.authenticationToken, extras: [:])))
             case .failed(let error):
                 self.delayed(.failure(error: error))
             case .cancelled:
                 self.cancel()
             }
     }

     func cancel() {
         self.delayed(.failure(error: WebAuthError.userCancelled))
     }

     func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
         return SDKApplicationDelegate.shared.application(app, open: url, options: options)
     }
 }
 ```
 */
public protocol NativeAuthTransaction: AuthTransaction {
    var scope: String { get }
    var connection: String { get }
    var parameters: [String: Any] { get }

    typealias Callback = (Result<NativeAuthCredentials>) -> ()
    func auth(callback: @escaping Callback) -> ()
}

public extension NativeAuthTransaction {

    var state: String? {
        return self.connection
    }

    public func start(callback: @escaping (Result<Credentials>) -> ()) {
        TransactionStore.shared.store(self)
        self.auth { result in
            switch result {
            case .success(let credentials):
                var parameters: [String: Any] = self.parameters
                credentials.extras.forEach { parameters[$0] = $1 }
                authentication().loginSocial(token: credentials.token, connection: self.connection, scope: self.scope, parameters: parameters)
                    .start(callback)
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
    }
}
