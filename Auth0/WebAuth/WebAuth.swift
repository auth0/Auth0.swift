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
import SafariServices

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
public func webAuth(bundle bundle: NSBundle = NSBundle.mainBundle()) -> WebAuth {
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
public func webAuth(clientId clientId: String, domain: String) -> WebAuth {
    return _WebAuth(clientId: clientId, url: .a0_url(domain))
}

/**
 Resumes the current Auth session (if any).

 - parameter url:     url received by iOS application in AppDelegate
 - parameter options: dictionary with launch options received by iOS application in AppDelegate

 - returns: if the url was handled by an on going session or not.
 */
public func resumeAuth(url: NSURL, options: [String: AnyObject]) -> Bool {
    return SessionStorage.sharedInstance.resume(url, options: options)
}

/// OAuth2 Authentication using Auth0
public protocol WebAuth: Trackable, Loggable {
    var clientId: String { get }
    var url: NSURL { get }
    var telemetry: Telemetry { get set }

    /**
     For redirect url instead of a custom scheme it will use `https` and iOS 9 Universal Links.

     Before enabling this flag you'll need to configure Universal Links

     - returns: the same OAuth2 instance to allow method chaining
     */
    func useUniversalLink() -> Self

    /**
     Specify a connection name to be used to authenticate.

     By default no connection is specified, so the hosted login page will be displayed

     - parameter connection: name of the connection to use

     - returns: the same OAuth2 instance to allow method chaining
     */
    func connection(connection: String) -> Self

    /**
     Scopes that will be requested during auth

     - parameter scope: a scope value like: `openid email`

     - returns: the same OAuth2 instance to allow method chaining
     */
    func scope(scope: String) -> Self

    /**
     State value that will be echoed after authentication
     in order to check that the response is from your request and not other.

     By default a random value is used.

     - parameter state: a state value to send with the auth request

     - returns: the same OAuth2 instance to allow method chaining
     */
    func state(state: String) -> Self

    /**
     Send additional parameters for authentication.

     - parameter parameters: additional auth parameters

     - returns: the same OAuth2 instance to allow method chaining
     */
    func parameters(parameters: [String: String]) -> Self

    /**
     Change the default grant used for auth from `code` (w/PKCE) to `token` (implicit grant)

     - returns: the same OAuth2 instance to allow method chaining
     */
    func usingImplicitGrant() -> Self

    /**
     Starts the OAuth2 flow by modally presenting a ViewController in the top-most controller.

     ```
     Auth0
     .oauth2(clientId: clientId, domain: "samples.auth0.com")
     .start { result in
        print(result)
     }
     ```

     Then from `AppDelegate` we just need to resume the OAuth2 Auth like this

     ```
     func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return Auth0.resumeAuth(url, options: options)
     }
     ```

     Any on going OAuth2 Auth session will be automatically cancelled when starting a new one,
     and it's corresponding callback with be called with a failure result of `Authentication.Error.Cancelled`

     - parameter callback: callback called with the result of the OAuth2 flow
     */
    func start(callback: Result<Credentials> -> ())
}

class _WebAuth: WebAuth {

    private static let NoBundleIdentifier = "com.auth0.this-is-no-bundle"

    let clientId: String
    let url: NSURL
    var telemetry: Telemetry

    let presenter: ControllerModalPresenter
    let storage: SessionStorage
    var logger: Logger?
    var state = generateDefaultState()
    var parameters: [String: String] = [:]
    var universalLink = false
    var usePKCE = true

    convenience init(clientId: String, url: NSURL, presenter: ControllerModalPresenter = ControllerModalPresenter(), telemetry: Telemetry = Telemetry()) {
        self.init(clientId: clientId, url: url, presenter: presenter, storage: SessionStorage.sharedInstance, telemetry: telemetry)
    }

    init(clientId: String, url: NSURL, presenter: ControllerModalPresenter, storage: SessionStorage, telemetry: Telemetry) {
        self.clientId = clientId
        self.url = url
        self.presenter = presenter
        self.storage = storage
        self.telemetry = telemetry
    }

    func useUniversalLink() -> Self {
        self.universalLink = true
        return self
    }

    func connection(connection: String) -> Self {
        self.parameters["connection"] = connection
        return self
    }

    func scope(scope: String) -> Self {
        self.parameters["scope"] = scope
        return self
    }

    func state(state: String) -> Self {
        self.state = state
        return self
    }

    func parameters(parameters: [String: String]) -> Self {
        parameters.forEach { self.parameters[$0] = $1 }
        return self
    }

    func usingImplicitGrant() -> Self {
        self.usePKCE = false
        return self
    }

    func start(callback: Result<Credentials> -> ()) {
        guard
            let redirectURL = self.redirectURL
            where !redirectURL.absoluteString.hasPrefix(_WebAuth.NoBundleIdentifier)
            else {
                return callback(Result.Failure(error: WebAuthError.NoBundleIdentifierFound))
            }
        let handler = self.handler(redirectURL)
        let authorizeURL = self.buildAuthorizeURL(withRedirectURL: redirectURL, defaults: handler.defaults)
        let (controller, finish) = newSafari(authorizeURL, callback: callback)
        let session = SafariSession(controller: controller, redirectURL: redirectURL, state: self.state, handler: handler, finish: finish, logger: self.logger)
        controller.delegate = session
        logger?.trace(authorizeURL, source: "Safari")
        self.presenter.present(controller)
        self.storage.store(session)
    }

    func newSafari(authorizeURL: NSURL, callback: Result<Credentials> -> ()) -> (SFSafariViewController, Result<Credentials> -> ()) {
        let controller = SFSafariViewController(URL: authorizeURL)
        let finish: Result<Credentials> -> () = { [weak controller] (result: Result<Credentials>) -> () in
            guard let presenting = controller?.presentingViewController else {
                return callback(Result.Failure(error: WebAuthError.CannotDismissWebAuthController))
            }

            if case .Failure(let cause as WebAuthError) = result, case .UserCancelled = cause {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(result)
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    presenting.dismissViewControllerAnimated(true) {
                        callback(result)
                    }
                }
            }
        }
        return (controller, finish)
    }

    func buildAuthorizeURL(withRedirectURL redirectURL: NSURL, defaults: [String: String]) -> NSURL {
        let authorize = NSURL(string: "/authorize", relativeToURL: self.url)!
        let components = NSURLComponents(URL: authorize, resolvingAgainstBaseURL: true)!
        var items: [NSURLQueryItem] = []
        var entries = defaults
        entries["client_id"] = self.clientId
        entries["redirect_uri"] = redirectURL.absoluteString
        entries["scope"] = "openid"
        entries["state"] = self.state
        self.parameters.forEach { entries[$0] = $1 }

        entries.forEach { items.append(NSURLQueryItem(name: $0, value: $1)) }
        components.queryItems = self.telemetry.queryItemsWithTelemetry(queryItems: items)
        return components.URL!
    }

    func handler(redirectURL: NSURL) -> OAuth2Grant {
        if self.usePKCE {
            var authentication = Authentication(clientId: self.clientId, url: self.url, telemetry: self.telemetry)
            authentication.logger = self.logger
            return PKCE(authentication: authentication, redirectURL: redirectURL)
        } else {
            return ImplicitGrant()
        }
    }

    var redirectURL: NSURL? {
        let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? _WebAuth.NoBundleIdentifier
        let components = NSURLComponents(URL: self.url, resolvingAgainstBaseURL: true)
        components?.scheme = self.universalLink ? "https" : bundleIdentifier
        return components?.URL?
            .URLByAppendingPathComponent("ios")
            .URLByAppendingPathComponent(bundleIdentifier)
            .URLByAppendingPathComponent("callback")
    }
}

private func generateDefaultState() -> String? {
    guard let data = NSMutableData(length: 32) else { return nil }
    if SecRandomCopyBytes(kSecRandomDefault, data.length, UnsafeMutablePointer<UInt8>(data.mutableBytes)) != 0 {
        return nil
    }
    return data.a0_encodeBase64URLSafe()
}