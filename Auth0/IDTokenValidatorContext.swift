// IDTokenValidatorContext.swift
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

#if WEB_AUTH_PLATFORM
import Foundation

struct IDTokenValidatorContext: IDTokenSignatureValidatorContext, IDTokenClaimsValidatorContext {
    let issuer: String
    let audience: String
    let jwksRequest: Request<JWKS, AuthenticationError>
    let nonce: String?
    let leeway: Int
    let maxAge: Int?

    init(issuer: String,
         audience: String,
         jwksRequest: Request<JWKS, AuthenticationError>,
         leeway: Int,
         maxAge: Int?,
         nonce: String?) {
        self.issuer = issuer
        self.audience = audience
        self.jwksRequest = jwksRequest
        self.leeway = leeway
        self.maxAge = maxAge
        self.nonce = nonce
    }

    init(authentication: Authentication, issuer: String, leeway: Int, maxAge: Int?, nonce: String?) {
        self.init(issuer: issuer,
                  audience: authentication.clientId,
                  jwksRequest: authentication.jwks(),
                  leeway: leeway,
                  maxAge: maxAge,
                  nonce: nonce)
    }
}
#endif
