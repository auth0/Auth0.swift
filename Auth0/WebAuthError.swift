// WebAuthError.swift
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

/**
 List of possible web-based authentication errors

 - NoBundleIdentifierFound:        Cannot get the App's Bundle Identifier to use for redirect_uri.
 - CannotDismissWebAuthController: When trying to dismiss WebAuth controller, no presenter controller could be found.
 - UserCancelled:                  User cancelled the web-based authentication, e.g. tapped the "Done" button in SFSafariViewController
 - PKCENotAllowed:                 PKCE for the supplied Auth0 ClientId was not allowed. You need to set the `Token Endpoint Authentication Method` to `None` in your Auth0 Dashboard
 */
public enum WebAuthError: ErrorType {
    case NoBundleIdentifierFound
    case CannotDismissWebAuthController
    case UserCancelled
    case PKCENotAllowed(String)
}

extension WebAuthError: FoundationErrorConvertible {
    static let FoundationDomain = "com.auth0.webauth"
    static let FoundationUserInfoKey = "com.auth0.webauth.error.info"
    static let GenericFoundationCode = 1
    static let CancelledFoundationCode = 0

    func newFoundationError() -> NSError {
        if case .UserCancelled = self {
            return NSError(
                domain: WebAuthError.FoundationDomain,
                code: WebAuthError.CancelledFoundationCode,
                userInfo: [
                    NSLocalizedDescriptionKey: "User Cancelled Web Authentication",
                    WebAuthError.FoundationUserInfoKey: self as NSError
                ]
            )
        }
        if case .PKCENotAllowed(let message) = self {
            return NSError(
                domain: WebAuthError.FoundationDomain,
                code: WebAuthError.GenericFoundationCode,
                userInfo: [
                    NSLocalizedDescriptionKey: message,
                    WebAuthError.FoundationUserInfoKey: self as NSError
                ]
            )
        }
        return NSError(
            domain: WebAuthError.FoundationDomain,
            code: WebAuthError.GenericFoundationCode,
            userInfo: [
                NSLocalizedDescriptionKey: (self as NSError).localizedDescription,
                WebAuthError.FoundationUserInfoKey: self as NSError
            ]
        )
    }
}