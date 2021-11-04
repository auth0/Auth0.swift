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

public typealias A0URLOptionsKey = UIApplication.OpenURLOptionsKey

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
        return resumeAuth(url)
    }

}

@available(iOS 13.0, *)
extension ASTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}

@available(iOS 13.0, *)
extension ASCallbackTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}
#endif
