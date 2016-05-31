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

    let clientId: String
    let url: NSURL
    let presenter: ControllerModalPresenter

    public enum Error: ErrorType {
        case WebControllerMissing
        case UnrecognizedRedirectParameters
    }

    public init(clientId: String, url: NSURL, presenter: ControllerModalPresenter = ControllerModalPresenter()) {
        self.clientId = clientId
        self.url = url
        self.presenter = presenter
    }

    public func start(callback: Result<Credentials, Authentication.Error> -> ()) -> OAuth2Session {
        let authorize = NSURL(string: "/authorize", relativeToURL: self.url)!
        let components = NSURLComponents(URL: authorize, resolvingAgainstBaseURL: true)!
        let redirectURL = NSURL(string: "com.auth0.OAuth2://overmind.auth0.com/ios/com.auth0.OAuth2/callback")!
        components.queryItems = [
            NSURLQueryItem(name: "client_id", value: self.clientId),
            NSURLQueryItem(name: "response_type", value: "token"),
            NSURLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString)
        ]
        let safari = SFSafariViewController(URL: components.URL!)
        let session = OAuth2Session(controller: safari, redirectURL: redirectURL, callback: callback)
        self.presenter.present(safari)
        return session
    }
} 
