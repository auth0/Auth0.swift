// DesktopWebAuth.swift
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

#if os(macOS)
import Cocoa
import AuthenticationServices

/**
 Resumes the current Auth session (if any).

 - parameter urls: urls received by the macOS application in AppDelegate
 - warning: deprecated as the SDK will not support macOS versions older than Catalina
 */
@available(*, deprecated, message: "the SDK will not support macOS versions older than Catalina")
public func resumeAuth(_ urls: [URL]) {
    guard let url = urls.first else { return }
    _ = TransactionStore.shared.resume(url)
}

public extension _ObjectiveOAuth2 {

    /**
     Resumes the current Auth session (if any).

     - parameter urls: urls received by the macOS application in AppDelegate
     - warning: deprecated as the SDK will not support macOS versions older than Catalina
     */
    @available(*, deprecated, message: "the SDK will not support macOS versions older than Catalina")
    @objc(resumeAuthWithURLs:)
    static func resume(_ urls: [URL]) {
        resumeAuth(urls)
    }

}

extension ASTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}

extension ASCallbackTransaction: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}
#endif
