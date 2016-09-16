// SafariWebAuth.swift
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

class SafariWebAuth: WebAuth {

    fileprivate static let NoBundleIdentifier = "com.auth0.this-is-no-bundle"

    let clientId: String
    let url: URL
    var telemetry: Telemetry

    let presenter: ControllerModalPresenter
    let storage: SessionStorage
    var logger: Logger?
    var state = generateDefaultState()
    var parameters: [String: String] = [:]
    var universalLink = false
    var usePKCE = true

    convenience init(clientId: String, url: URL, presenter: ControllerModalPresenter = ControllerModalPresenter(), telemetry: Telemetry = Telemetry()) {
        self.init(clientId: clientId, url: url, presenter: presenter, storage: SessionStorage.sharedInstance, telemetry: telemetry)
    }

    init(clientId: String, url: URL, presenter: ControllerModalPresenter, storage: SessionStorage, telemetry: Telemetry) {
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

    func connection(_ connection: String) -> Self {
        self.parameters["connection"] = connection
        return self
    }

    func scope(_ scope: String) -> Self {
        self.parameters["scope"] = scope
        return self
    }

    func state(_ state: String) -> Self {
        self.state = state
        return self
    }

    func parameters(_ parameters: [String: String]) -> Self {
        parameters.forEach { self.parameters[$0] = $1 }
        return self
    }

    func usingImplicitGrant() -> Self {
        self.usePKCE = false
        return self
    }

    func start(_ callback: @escaping (Result<Credentials>) -> ()) {
        guard
            let redirectURL = self.redirectURL
            , !redirectURL.absoluteString.hasPrefix(SafariWebAuth.NoBundleIdentifier)
            else {
                return callback(Result.failure(error: WebAuthError.noBundleIdentifierFound))
        }
        let handler = self.handler(redirectURL)
        let authorizeURL = self.buildAuthorizeURL(withRedirectURL: redirectURL, defaults: handler.defaults)
        let (controller, finish) = newSafari(authorizeURL, callback: callback)
        let session = SafariSession(controller: controller, redirectURL: redirectURL, state: self.state, handler: handler, finish: finish, logger: self.logger)
        controller.delegate = session
        logger?.trace(url: authorizeURL, source: "Safari")
        self.presenter.present(controller)
        self.storage.store(session)
    }

    func newSafari(_ authorizeURL: URL, callback: @escaping (Result<Credentials>) -> ()) -> (SFSafariViewController, (Result<Credentials>) -> ()) {
        let controller = SFSafariViewController(url: authorizeURL)
        let finish: (Result<Credentials>) -> () = { [weak controller] (result: Result<Credentials>) -> () in
            guard let presenting = controller?.presentingViewController else {
                return callback(Result.failure(error: WebAuthError.cannotDismissWebAuthController))
            }

            if case .failure(let cause as WebAuthError) = result, case .userCancelled = cause {
                DispatchQueue.main.async {
                    callback(result)
                }
            } else {
                DispatchQueue.main.async {
                    presenting.dismiss(animated: true) {
                        callback(result)
                    }
                }
            }
        }
        return (controller, finish)
    }

    func buildAuthorizeURL(withRedirectURL redirectURL: URL, defaults: [String: String]) -> URL {
        let authorize = URL(string: "/authorize", relativeTo: self.url)!
        var components = URLComponents(url: authorize, resolvingAgainstBaseURL: true)!
        var items: [URLQueryItem] = []
        var entries = defaults
        entries["client_id"] = self.clientId
        entries["redirect_uri"] = redirectURL.absoluteString
        entries["scope"] = "openid"
        entries["state"] = self.state
        self.parameters.forEach { entries[$0] = $1 }

        entries.forEach { items.append(URLQueryItem(name: $0, value: $1)) }
        components.queryItems = self.telemetry.queryItemsWithTelemetry(queryItems: items)
        return components.url!
    }

    func handler(_ redirectURL: URL) -> OAuth2Grant {
        if self.usePKCE {
            var authentication = Auth0Authentication(clientId: self.clientId, url: self.url, telemetry: self.telemetry)
            authentication.logger = self.logger
            return PKCE(authentication: authentication, redirectURL: redirectURL)
        } else {
            return ImplicitGrant()
        }
    }

    var redirectURL: URL? {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? SafariWebAuth.NoBundleIdentifier
        var components = URLComponents(url: self.url, resolvingAgainstBaseURL: true)
        components?.scheme = self.universalLink ? "https" : bundleIdentifier
        return components?.url?
            .appendingPathComponent("ios")
            .appendingPathComponent(bundleIdentifier)
            .appendingPathComponent("callback")
    }
}

private func generateDefaultState() -> String? {
    var data = Data(count: 32)

    let result = data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Int in
        return Int(SecRandomCopyBytes(kSecRandomDefault, data.count, bytes))
    }

    guard result == 0 else { return nil }
    return data.a0_encodeBase64URLSafe()
}
