// OAuth2Session.swift
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

public class OAuth2Session: NSObject {
    weak var controller: UIViewController?
    let redirectURL: NSURL
    let state: String?
    let callback: Result<Credentials, Authentication.Error> -> Bool

    init(controller: UIViewController, redirectURL: NSURL, state: String? = nil, callback: Result<Credentials, Authentication.Error> -> Bool) {
        self.controller = controller
        self.redirectURL = redirectURL
        self.state = state
        self.callback = callback
    }

    public func resume(url: NSURL, options: [String: AnyObject] = [:]) -> Bool {
        guard url.absoluteString.lowercaseString.hasPrefix(self.redirectURL.absoluteString.lowercaseString) else { return false }

        guard
            let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
            else {
                self.callback(.Failure(error: .InvalidResponse(response: url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding))))
                return false
            }
        let items = values(components)
        guard self.state == nil || items["state"] == self.state else { return false }
        guard let credentials = Credentials(json: items) else {
            self.callback(.Failure(error: .InvalidResponse(response: url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding))))
            return false
        }

        self.callback(.Success(result: credentials))
        return true
    }
}

extension OAuth2Session: SFSafariViewControllerDelegate {
    convenience init(controller: SFSafariViewController, redirectURL: NSURL, state: String? = nil, callback: Result<Credentials, Authentication.Error> -> ()) {

        let finish = { [weak controller] (result: Result<Credentials, Authentication.Error>) -> Bool in
            guard let presenting = controller?.presentingViewController else {
                callback(Result.Failure(error: .RequestFailed(cause: OAuth2.Error.WebControllerMissing)))
                return false
            }

            dispatch_async(dispatch_get_main_queue()) {
                presenting.dismissViewControllerAnimated(true) {
                    callback(result)
                }
            }

            return true
        }

        self.init(controller: controller, redirectURL: redirectURL, state: state, callback: finish)
        controller.delegate = self
    }

    public func safariViewControllerDidFinish(controller: SFSafariViewController) {
        self.callback(Result.Failure(error: .Cancelled))
    }
}

private func values(components: NSURLComponents) -> [String: String] {
    if let fragment = components.fragment {
        return fragmentDictionary(fragment)
    } else {
        return queryDictionary(components.queryItems)
    }
}

private func fragmentDictionary(fragment: String) -> [String: String] {
    var dict: [String: String] = [:]
    let items = fragment.componentsSeparatedByString("&")
    items.forEach { item in
        let parts = item.componentsSeparatedByString("=")
        guard
            parts.count == 2,
            let key = parts.first,
            let value = parts.last
        else { return }
        dict[key] = value
    }
    return dict
}

private func queryDictionary(queryItems: [NSURLQueryItem]?) -> [String: String] {
    var dict: [String: String] = [:]
    queryItems?.forEach { dict[$0.name] = $0.value }
    return dict
}