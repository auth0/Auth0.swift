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

/**
 Represents an on going OAuth2 session with Auth0.
 
 It will handle result from the redirect URL configured when the OAuth2 flow was started,
 so we need to handle when the configured URL is opened in your Application's `AppDelegate`
 
 ```
 func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    let session = //retrieve current OAuth2 session
    return session.resume(url, options: options)
 }
 ```
 */
class OAuth2Session: NSObject {

    typealias FinishSession = Result<Credentials, Authentication.Error> -> ()

    weak var controller: UIViewController?

    let redirectURL: NSURL
    let state: String?
    let finish: FinishSession
    let handler: OAuth2Grant

    init(controller: SFSafariViewController, redirectURL: NSURL, state: String? = nil, handler: OAuth2Grant, finish: FinishSession) {
        self.controller = controller
        self.redirectURL = redirectURL
        self.state = state
        self.finish = finish
        self.handler = handler
        super.init()
        controller.delegate = self
    }

    /**
     Tries to resume (and complete) the OAuth2 session from the received URL

     - parameter url:     url received in application's AppDelegate
     - parameter options: a dictionary of launch options received from application's AppDelegate

     - returns: `true` if the url completed (successfuly or not) this session, `false` otherwise
     */
    func resume(url: NSURL, options: [String: AnyObject] = [:]) -> Bool {
        guard url.absoluteString.lowercaseString.hasPrefix(self.redirectURL.absoluteString.lowercaseString) else { return false }

        guard
            let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
            else {
                self.finish(.Failure(error: .InvalidResponse(response: url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding))))
                return false
            }
        let items = components.a0_values
        guard self.state == nil || items["state"] == self.state else { return false }
        if let error = items["error"] {
            guard let description = items["error_description"] else {
                self.finish(.Failure(error: .InvalidResponse(response: url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding))))
                return true
            }
            self.finish(.Failure(error: .Response(code: error, description: description, name: nil, extras: nil)))
        } else {
            self.handler.credentials(items, callback: self.finish)
        }
        return true
    }

    func cancel() {
        self.finish(Result.Failure(error: .Cancelled))
    }
}

extension OAuth2Session: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        SessionStorage.sharedInstance.cancel(self)
    }
}