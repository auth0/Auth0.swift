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

#if WEB_AUTH_PLATFORM
import Foundation

/**
 List of possible web-based authentication errors

 - NoBundleIdentifierFound:        Cannot get the App's Bundle Identifier to use for redirect_uri.
 - CannotDismissWebAuthController: When trying to dismiss WebAuth controller, no presenter controller could be found.
 - UserCancelled:                  User cancelled the web-based authentication, e.g. tapped the "Done" button in SFSafariViewController
 - PKCENotAllowed:                 PKCE for the supplied Auth0 ClientId was not allowed. You need to set the `Token Endpoint Authentication Method` to `None` in your Auth0 Dashboard
 - noNonceProvided:                A nonce value must be provided to use the response option of id_token
 - invalidIdTokenNonce:            Failed to match token nonce with request nonce
 - missingAccessToken:             access_token missing in response
 */
public enum WebAuthError: CustomNSError {
    case noBundleIdentifierFound
    case cannotDismissWebAuthController
    case userCancelled
    case pkceNotAllowed(String)
    case noNonceProvided
    case missingResponseParam(String)
    case invalidIdTokenNonce // TODO: Remove on the next major
    case missingAccessToken
    case unknownError

    static let genericFoundationCode = 1
    static let cancelledFoundationCode = 0

    public static let infoKey = "com.auth0.webauth.error.info"
    public static let errorDomain: String = "com.auth0.webauth"

    public var errorCode: Int {
        switch self {
        case .userCancelled:
            return WebAuthError.cancelledFoundationCode
        default:
            return WebAuthError.genericFoundationCode
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case .userCancelled:
            return [
                NSLocalizedDescriptionKey: "User Cancelled Web Authentication",
                WebAuthError.infoKey: self
            ]
        case .pkceNotAllowed(let message):
            return [
                NSLocalizedDescriptionKey: message,
                WebAuthError.infoKey: self
            ]
        case .noNonceProvided:
            return [
                NSLocalizedDescriptionKey: "A nonce value must be supplied when response_type includes id_token in order to prevent replay attacks",
                WebAuthError.infoKey: self
            ]
        case .invalidIdTokenNonce:
            return [
                NSLocalizedDescriptionKey: "Could not validate the id_token",
                WebAuthError.infoKey: self
            ]
        case .missingAccessToken:
            return [
                NSLocalizedDescriptionKey: "Could not validate the token",
                WebAuthError.infoKey: self
            ]
        default:
            return [
                NSLocalizedDescriptionKey: "Failed to perform webAuth",
                WebAuthError.infoKey: self
            ]
        }
    }
}
#endif
