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

class SafariWebAuth: SafariWebAuthenticatable {

    let presenter: ControllerModalPresenter

    init(clientId: String, url: URL, presenter: ControllerModalPresenter = ControllerModalPresenter(), telemetry: Telemetry = Telemetry()) {
        self.presenter = presenter
        super.init(clientId: clientId, url: url, storage: TransactionStore.shared, telemetry: telemetry)
    }

    override func start(_ callback: @escaping (Result<Credentials>) -> Void) {
        guard
            let redirectURL = self.redirectURL, !redirectURL.absoluteString.hasPrefix(SafariWebAuth.NoBundleIdentifier)
            else {
                return callback(Result.failure(error: WebAuthError.noBundleIdentifierFound))
        }
        if self.responseType.contains(.idToken) {
            guard self.nonce != nil else { return callback(Result.failure(error: WebAuthError.noNonceProvided)) }
        }
        let handler = self.handler(redirectURL)
        let state = self.parameters["state"] ?? generateDefaultState()
        let authorizeURL = self.buildAuthorizeURL(withRedirectURL: redirectURL, defaults: handler.defaults, state: state)
        let (controller, finish) = newSafari(authorizeURL, callback: callback)

        let session = SafariSession(controller: controller, redirectURL: redirectURL, state: state, handler: handler, finish: finish, logger: self.logger)
        controller.delegate = session
        logger?.trace(url: authorizeURL, source: "Safari")
        self.presenter.present(controller: controller)
        self.storage.store(session)
    }

    func newSafari(_ authorizeURL: URL, callback: @escaping (Result<Credentials>) -> Void) -> (SFSafariViewController, (Result<Credentials>) -> Void) {
        let controller = SFSafariViewController(url: authorizeURL)
        let finish: (Result<Credentials>) -> Void = { [weak controller] (result: Result<Credentials>) -> Void in
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
}
