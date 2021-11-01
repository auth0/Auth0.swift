// MobileWebAuth.swift
//
// Copyright (c) 2020 Auth0 (http://auth0.com)
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

#if os(iOS)
import UIKit
import SafariServices
import AuthenticationServices

#if swift(>=4.2)
public typealias A0URLOptionsKey = UIApplication.OpenURLOptionsKey
#else
public typealias A0URLOptionsKey = UIApplicationOpenURLOptionsKey
#endif

/**
 Resumes the current Auth session (if any).

 - parameter url:     url received by the iOS application in AppDelegate
 - parameter options: dictionary with launch options received by the iOS application in AppDelegate

 - returns: if the url was handled by an on going session or not.
 */
@available(*, deprecated, message: "this method is not needed when targeting iOS 11+")
public func resumeAuth(_ url: URL, options: [A0URLOptionsKey: Any] = [:]) -> Bool {
    return TransactionStore.shared.resume(url)
}

public extension _ObjectiveOAuth2 {

    /**
     Resumes the current Auth session (if any).

     - parameter url:     url received by iOS application in AppDelegate
     - parameter options: dictionary with launch options received by iOS application in AppDelegate

     - returns: if the url was handled by an on going session or not.
     */
    @objc(resumeAuthWithURL:options:)
    static func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        return resumeAuth(url, options: options)
    }

}

public protocol AuthResumable {

    /**
     Resumes the transaction when the third party application notifies the application using a url with a custom scheme.
     This method should be called from the Application's `AppDelegate` or using `public func resumeAuth(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool` method.
     
     - parameter url: the url send by the third party application that contains the result of the Auth
     - parameter options: options received in the openUrl method of the `AppDelegate`

     - returns: if the url was expected and properly formatted otherwise it will return `false`.
    */
    func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool

}

public extension AuthResumable {

    /**
    Tries to resume (and complete) the OAuth2 session from the received URL

    - parameter url:     url received in application's AppDelegate
    - parameter options: a dictionary of launch options received from application's AppDelegate

    - returns: `true` if the url completed (successfully or not) this session, `false` otherwise
    */
    func resume(_ url: URL, options: [A0URLOptionsKey: Any] = [:]) -> Bool {
        return self.resume(url, options: options)
    }

}

extension AuthTransaction where Self: SessionCallbackTransaction {

    func resume(_ url: URL, options: [A0URLOptionsKey: Any]) -> Bool {
        return self.handleUrl(url)
    }

}

#if swift(>=5.1)
@available(iOS 13.0, *)
extension AuthenticationServicesSession: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}

@available(iOS 13.0, *)
extension AuthenticationServicesSessionCallback: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}
#endif
#endif
