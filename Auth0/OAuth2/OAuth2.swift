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

    private static let NoBundleIdentifier = "com.auth0.no-bundle"
    let clientId: String
    let url: NSURL
    let presenter: ControllerModalPresenter
    var state = generateDefaultState()
    var parameters: [String: String] = [:]

    public enum Error: ErrorType {
        case WebControllerMissing
        case NoBundleIdentifier
    }

    public init(clientId: String, url: NSURL, presenter: ControllerModalPresenter = ControllerModalPresenter()) {
        self.clientId = clientId
        self.url = url
        self.presenter = presenter
    }

    public func connection(connection: String) -> OAuth2 {
        self.parameters["connection"] = connection
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

    public func start(callback: Result<Credentials, Authentication.Error> -> ()) -> OAuth2Session? {
        guard
            let redirectURL = self.redirectURL
            where !redirectURL.absoluteString.hasPrefix(OAuth2.NoBundleIdentifier)
            else {
                callback(Result.Failure(error: .RequestFailed(cause: Error.NoBundleIdentifier)))
                return nil
            }
        let safari = SFSafariViewController(URL: buildAuthorizeURL(withRedirectURL: redirectURL))
        let session = OAuth2Session(controller: safari, redirectURL: redirectURL, state: self.state, callback: callback)
        self.presenter.present(safari)
        return session
    }

    func buildAuthorizeURL(withRedirectURL redirectURL: NSURL) -> NSURL {
        let authorize = NSURL(string: "/authorize", relativeToURL: self.url)!
        let components = NSURLComponents(URL: authorize, resolvingAgainstBaseURL: true)!
        var items = [
            NSURLQueryItem(name: "client_id", value: self.clientId),
            NSURLQueryItem(name: "response_type", value: "token"),
            NSURLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
            NSURLQueryItem(name: "state", value: self.state),
        ]
        parameters.forEach { items.append(NSURLQueryItem(name: $0, value: $1)) }
        components.queryItems = items
        return components.URL!
    }

    var redirectURL: NSURL? {
        let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? OAuth2.NoBundleIdentifier
        let components = NSURLComponents(URL: self.url, resolvingAgainstBaseURL: true)
        components?.scheme = bundleIdentifier
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

extension NSMutableData {
    func a0_encodeBase64URLSafe() -> String? {
        return self
            .base64EncodedStringWithOptions([])
            .stringByReplacingOccurrencesOfString("+", withString: "-")
            .stringByReplacingOccurrencesOfString("/", withString: "_")
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "="))
    }
}
