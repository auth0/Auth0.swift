// _ObjectiveWebAuth.swift
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

@objc(A0WebAuth)
/// Web-based Auth with Auth0
// swiftlint:disable:next type_name
public class _ObjectiveOAuth2: NSObject {

    private(set) var webAuth: SafariWebAuth

    @objc public override init() {
        let values = plistValues(bundle: Bundle.main)!
        self.webAuth = SafariWebAuth(clientId: values.clientId, url: .a0_url(values.domain))
    }

    @objc public init(clientId: String, url: URL) {
        self.webAuth = SafariWebAuth(clientId: clientId, url: url)
    }

    @objc public func addParameters(_ parameters: [String: String]) {
        _ = self.webAuth.parameters(parameters)
    }

    /**
     For redirect url instead of a custom scheme it will use `https` and iOS 9 Universal Links.

     Before enabling this flag you'll need to configure Universal Links
    */
    @objc public var universalLink: Bool {
        set {
            self.webAuth.universalLink = newValue
        }
        get {
            return self.webAuth.universalLink
        }
    }

    /**
     Specify a connection name to be used to authenticate.

     By default no connection is specified, so the hosted login page will be displayed
    */
    @objc public var connection: String? {
        set {
            if let value = newValue {
                _ = self.webAuth.connection(value)
            }
        }
        get {
            return self.webAuth.parameters["connection"]
        }
    }

    /**
     Scopes that will be requested during auth
    */
    @objc public var scope: String? {
        set {
            if let value = newValue {
                _ = self.webAuth.scope(value)
            }
        }
        get {
            return self.webAuth.parameters["scope"]
        }
    }

    /**
     Starts the web-based auth flow by modally presenting a ViewController in the top-most controller.

     ```
     A0WebAuth *auth = [[A0WebAuth alloc] initWithClientId:clientId url: url];
     [auth startWithCallback:^(NSError *error, A0Credentials *credentials) {
        NSLog(@"error: %@, credetials: %@", error, credentials);
     }];
     ```

     Then from `AppDelegate` we just need to resume the OAuth2 Auth like this

     ```
     - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id>)*options {
        return [A0OAuth2 resumeAuthWithURL:url options:options];
     }
     ```

     - parameter callback: callback called with the result of the OAuth2 flow

     - returns: an object representing the current OAuth2 session.
     */
    @objc public func start(_ callback: @escaping (NSError?, Credentials?) -> Void) {
        self.webAuth.start { result in
            switch result {
            case .success(let credentials):
                callback(nil, credentials)
            case .failure(let cause):
                callback(cause as NSError, nil)
            }
        }
    }

    /**
     Resumes the current Auth session (if any).

     - parameter url:     url received by iOS application in AppDelegate
     - parameter options: dictionary with launch options received by iOS application in AppDelegate

     - returns: if the url was handled by an on going session or not.
     */
    @objc(resumeAuthWithURL:options:)
    public static func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        return TransactionStore.shared.resume(url, options: options)
    }

    /**
     Avoid Auth0.swift sending its version on every request to Auth0 API.
     By default we collect our libraries and SDKs versions to help us during support and evaluate usage.

     - parameter enabled: if Auth0.swift should send it's version on every request.
     */
    @objc public func setTelemetryEnabled(_ enabled: Bool) {
        self.webAuth.tracking(enabled: enabled)
    }
}
