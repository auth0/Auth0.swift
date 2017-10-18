// WebAuth.swift
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

import UIKit

/**
 Auth0 iOS component for authenticating with web-based flow

 ```
 Auth0.webAuth()
 ```

 Auth0 domain is loaded from the file `Auth0.plist` in your main bundle with the following content:

 ```
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
	<key>ClientId</key>
	<string>{YOUR_CLIENT_ID}</string>
	<key>Domain</key>
	<string>{YOUR_DOMAIN}</string>
 </dict>
 </plist>
 ```

 - parameter bundle:    bundle used to locate the `Auth0.plist` file. By default is the main bundle

 - returns: Auth0 WebAuth component
 - important: Calling this method without a valid `Auth0.plist` will crash your application
 */
public func webAuth(bundle: Bundle = Bundle.main) -> WebAuth {
    let values = plistValues(bundle: bundle)!
    return webAuth(clientId: values.clientId, domain: values.domain)
}

/**
 Auth0 iOS component for authenticating with web-based flow

 ```
 Auth0.webAuth(clientId: clientId, domain: "samples.auth0.com")
 ```

 - parameter clientId: id of your Auth0 client
 - parameter domain:   name of your Auth0 domain

 - returns: Auth0 WebAuth component
 */
public func webAuth(clientId: String, domain: String) -> WebAuth {
    return SafariWebAuth(clientId: clientId, url: .a0_url(domain))
}

/**
 Resumes the current Auth session (if any).

 - parameter url:     url received by iOS application in AppDelegate
 - parameter options: dictionary with launch options received by iOS application in AppDelegate

 - returns: if the url was handled by an on going session or not.
 */
public func resumeAuth(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
    return TransactionStore.shared.resume(url, options: options)
}

/// WebAuth Authentication using Auth0
public protocol WebAuth: Trackable, Loggable {
    var clientId: String { get }
    var url: URL { get }
    var telemetry: Telemetry { get set }

    /**
     For redirect url instead of a custom scheme it will use `https` and iOS 9 Universal Links.

     Before enabling this flag you'll need to configure Universal Links

     - returns: the same WebAuth instance to allow method chaining
     */
    func useUniversalLink() -> Self

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

    /// Setup the response types to be used for authentcation
    ///
    /// - Parameter response: Array of ResponseOptions
    /// - Returns: the same WebAuth instance to allow method chaining
    func responseType(_ response: [ResponseType]) -> Self

    /// Add nonce paramater for authentication, this is a requirement for
    /// when response type .id_token is specified.
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

    /**
     Change the default grant used for auth from `code` (w/PKCE) to `token` (implicit grant)

     - returns: the same WebAuth instance to allow method chaining
     */
    @available(*, deprecated, message: "use response([.token])")
    func usingImplicitGrant() -> Self

    /**
     Use `SFSafariViewController` instead of `SFAuthenticationSession` for WebAuth
     in iOS 11.0+.

     - returns: the same WebAuth instance to allow method chaining
     */
    @available(iOS 11, *)
    func useLegacyAuthentication() -> Self

    /**
     Starts the WebAuth flow by modally presenting a ViewController in the top-most controller.

     ```
     Auth0
         .webAuth(clientId: clientId, domain: "samples.auth0.com")
         .start { result in
             print(result)
         }
     ```

     Then from `AppDelegate` we just need to resume the WebAuth Auth like this

     ```
     func application(app: UIApplication, openURL url: NSURL, options: [String : Any]) -> Bool {
         return Auth0.resumeAuth(url, options: options)
     }
     ```

     Any on going WebAuth Auth session will be automatically cancelled when starting a new one,
     and it's corresponding callback with be called with a failure result of `Authentication.Error.Cancelled`

     - parameter callback: callback called with the result of the WebAuth flow
     */
    func start(_ callback: @escaping (Result<Credentials>) -> Void)

    /**
     Removes Auth0 session and optionally remove the Identity Provider session.
     - seeAlso: [Auth0 Logout docs](https://auth0.com/docs/logout)

     For iOS 11+ you will need to ensure that the **Callback URL** has been added
     to the **Allowed Logout URLs** section of your client in the [Auth0 Dashboard](https://manage.auth0.com/#/clients/).


     ```
     Auth0
         .webAuth()
         .clearSession { print($0) }
     ```

     Remove Auth0 session and remove the IdP session.

     ```
     Auth0
         .webAuth()
         .clearSession(federated: true) { print($0) }
     ```

     - parameter federated: Bool to remove the IdP session
     - parameter callback: callback called with bool outcome of the call
     */
    func clearSession(federated: Bool, callback: @escaping (Bool) -> Void)
}
