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

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

public typealias WebAuth = WebAuthenticatable
typealias Auth0WebAuth = DesktopWebAuth

/**
 Resumes the current Auth session (if any).

 - parameter urls: urls received by the macOS application in AppDelegate
 */
public func resumeAuth(_ urls: [URL]) {
    guard let url = urls.first else { return }
    _ = TransactionStore.shared.resume(url)
}

final class DesktopWebAuth: BaseWebAuth {

    init(clientId: String,
         url: URL,
         storage: TransactionStore = TransactionStore.shared,
         telemetry: Telemetry = Telemetry()) {
        super.init(platform: "macos",
                   clientId: clientId,
                   url: url,
                   storage: storage,
                   telemetry: telemetry)
    }

}

public extension _ObjectiveOAuth2 {

    /**
     Resumes the current Auth session (if any).

     - parameter urls: urls received by the macOS application in AppDelegate
     */
    @objc(resumeAuthWithURLs:)
    static func resume(_ urls: [URL]) {
        resumeAuth(urls)
    }

}

public protocol AuthResumable {

    /**
     Resumes the transaction when the third party application notifies the application using an url with a custom scheme.
     This method should be called from the Application's `AppDelegate` or by using the `public func resumeAuth(_ urls: [URL])` method.
     
     - parameter url: the url sent by the third party application that contains the result of the Auth

     - returns: if the url was expected and properly formatted otherwise it will return `false`.
    */
    func resume(_ url: URL) -> Bool

}

extension AuthTransaction where Self: BaseAuthTransaction {

    func resume(_ url: URL) -> Bool {
        return self.handleUrl(url)
    }

}

extension AuthTransaction where Self: SessionCallbackTransaction {

    func resume(_ url: URL) -> Bool {
        return self.handleUrl(url)
    }

}

#if canImport(AuthenticationServices) && swift(>=5.1)
@available(macOS 10.15, *)
extension AuthenticationServicesSession: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}

@available(macOS 10.15, *)
extension AuthenticationServicesSessionCallback: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared()?.windows.filter({ $0.isKeyWindow }).last ?? ASPresentationAnchor()
    }

}
#endif
