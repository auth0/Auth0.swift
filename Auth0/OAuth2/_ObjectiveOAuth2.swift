// _ObjectiveOAuth2.swift
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

import Foundation

@objc(A0OAuth2)
/// OAuth2 Auth with Auth0
public class _ObjectiveOAuth2: NSObject {

    private let oauth2: OAuth2

    public init(clientId: String, url: NSURL) {
        self.oauth2 = OAuth2(clientId: clientId, url: url)
    }

    func addParameters(parameters: [String: String]) {
        self.oauth2.parameters(parameters)
    }

    /**
     For redirect url instead of a custom scheme it will use `https` and iOS 9 Universal Links.

     Before enabling this flag you'll need to configure Universal Links
    */
    public var universalLink: Bool {
        set {
            self.oauth2.universalLink = newValue
        }
        get {
            return self.oauth2.universalLink
        }
    }

    /**
     Specify a connection name to be used to authenticate.

     By default no connection is specified, so the hosted login page will be displayed
    */
    public var connection: String? {
        set {
            if let value = newValue {
                self.oauth2.connection(value)
            }
        }
        get {
            return self.oauth2.parameters["connection"]
        }
    }

    /**
     Scopes that will be requested during auth
    */
    public var scope: String? {
        set {
            if let value = newValue {
                self.oauth2.scope(value)
            }
        }
        get {
            return self.oauth2.parameters["scope"]
        }
    }

    /**
     Starts the OAuth2 flow by modally presenting a ViewController in the top-most controller.

     ```
     A0OAuth2 *oauth2 = [[A0OAuth2 alloc] initWithClientId:clientId url: url];
     A0OAuth2Session *session= [oauth2 startWithCallback:^(NSError *error, A0Credentials *credentials) {
        NSLog(@"error: %@, credetials: %@", error, credentials);
     }];
     ```

     The returned session must be kept alive until the OAuth2 flow is completed and used from `AppDelegate`
     when the following method is called

     ```
     - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id>)*options {
        A0OAuth2Session *session = //retrieve current OAuth2 session
        return [session resumeWithURL:url options:options];
     }
     ```

     - parameter callback: callback called with the result of the OAuth2 flow

     - returns: an object representing the current OAuth2 session.
     */
    public func start(callback: (NSError?, Credentials?) -> ()) -> OAuth2Session? {
        return self.oauth2.start { result in
            switch result {
            case .Success(let credentials):
                callback(nil, credentials)
            case .Failure(let cause):
                callback(cause.foundationError, nil)
            }
        }
    }
}
