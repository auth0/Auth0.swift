// OAuth2.swift
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

public func oauth2(clientId clientId: String, domain: String) -> OAuth2 {
    return OAuth2(clientId: clientId, url: NSURL.a0_url(domain))
}

public class OAuth2: NSObject {

    private static let NoBundleIdentifier = "com.auth0.this-is-no-bundle"
    let clientId: String
    let url: NSURL
    let presenter: ControllerModalPresenter
    var state = generateDefaultState()
    var parameters: [String: String] = [:]
    var universalLink = false
    var usePKCE = true

    public enum Error: ErrorType {
        case WebControllerMissing
        case NoBundleIdentifier
    }

    public init(clientId: String, url: NSURL, presenter: ControllerModalPresenter = ControllerModalPresenter()) {
        self.clientId = clientId
        self.url = url
        self.presenter = presenter
    }

    public func universalLink(universalLink: Bool) -> OAuth2 {
        self.universalLink = universalLink
        return self
    }

    public func connection(connection: String) -> OAuth2 {
        self.parameters["connection"] = connection
        return self
    }

    public func scope(scope: String) -> OAuth2 {
        self.parameters["scope"] = scope
        return self
    }

    public func state(state: String) -> OAuth2 {
        self.state = state
        return self
    }

    public func parameters(parameters: [String: String]) -> OAuth2 {
        parameters.forEach { self.parameters[$0] = $1 }
        return self
    }

    public func usingImplicitGrant() -> OAuth2 {
        self.usePKCE = false
        return self
    }

    public func start(callback: Result<Credentials, Authentication.Error> -> ()) -> OAuth2Session? {
        guard
            let redirectURL = self.redirectURL
            where !redirectURL.absoluteString.hasPrefix(OAuth2.NoBundleIdentifier)
            else {
                callback(Result.Failure(error: .RequestFailed(cause: Error.NoBundleIdentifier)))
                return nil
            }
        let handler = self.handler(redirectURL)
        let authorizeURL = self.buildAuthorizeURL(withRedirectURL: redirectURL, defaults: handler.defaults)
        let (controller, finish) = newSafari(authorizeURL, callback: callback)
        let session = OAuth2Session(controller: controller, redirectURL: redirectURL, state: self.state, handler: handler, finish: finish)
        controller.delegate = session
        self.presenter.present(controller)
        return session
    }

    func newSafari(authorizeURL: NSURL, callback: Result<Credentials, Authentication.Error> -> ()) -> (SFSafariViewController, Result<Credentials, Authentication.Error> -> ()) {
        let controller = SFSafariViewController(URL: authorizeURL)
        let finish: Result<Credentials, Authentication.Error> -> () = { [weak controller] (result: Result<Credentials, Authentication.Error>) -> () in
            guard let presenting = controller?.presentingViewController else {
                return callback(Result.Failure(error: .RequestFailed(cause: OAuth2.Error.WebControllerMissing)))
            }

            dispatch_async(dispatch_get_main_queue()) {
                presenting.dismissViewControllerAnimated(true) {
                    callback(result)
                }
            }
        }
        return (controller, finish)
    }

    func buildAuthorizeURL(withRedirectURL redirectURL: NSURL, defaults: [String: String]) -> NSURL {
        let authorize = NSURL(string: "/authorize", relativeToURL: self.url)!
        let components = NSURLComponents(URL: authorize, resolvingAgainstBaseURL: true)!
        var items = [
            NSURLQueryItem(name: "client_id", value: self.clientId),
            NSURLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
            NSURLQueryItem(name: "state", value: state),
            ]

        let addAll: (String, String) -> () = { items.append(NSURLQueryItem(name: $0, value: $1)) }
        defaults.forEach(addAll)
        self.parameters.forEach(addAll)
        components.queryItems = items
        return components.URL!
    }

    func handler(redirectURL: NSURL) -> OAuth2Grant {
        return self.usePKCE ? PKCE(clientId: clientId, url: url, redirectURL: redirectURL) : ImplicitGrant()
    }

    var redirectURL: NSURL? {
        let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? OAuth2.NoBundleIdentifier
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

public extension NSData {
    public func a0_encodeBase64URLSafe() -> String? {
        return self
            .base64EncodedStringWithOptions([])
            .stringByReplacingOccurrencesOfString("+", withString: "-")
            .stringByReplacingOccurrencesOfString("/", withString: "_")
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "="))
    }
}
