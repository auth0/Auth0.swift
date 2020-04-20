// BaseAuthTransactionSpec.swift
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

import Quick
import Nimble
import OHHTTPStubs

@testable import Auth0

class BaseAuthTransactionSpec: QuickSpec {
    
    private let ClientId = "CLIENT_ID"
    private let Domain = URL(string: "https://samples.auth0.com")!
    private let Leeway = 60 * 1000
    private let RedirectURL = URL(string: "https://samples.auth0.com/callback")!

    override func spec() {
        var transaction: BaseAuthTransaction!
        var result: Result<Credentials>? = nil
        let callback: (Result<Credentials>) -> () = { result = $0 }
        let authentication = Auth0Authentication(clientId: ClientId, url: Domain)
        let generator = A0SHA256ChallengeGenerator()
        let handler = PKCE(authentication: authentication,
                           redirectURL: RedirectURL,
                           generator: generator,
                           responseType: [.code],
                           leeway: Leeway,
                           nonce: nil)
        let idToken = generateJWT().string
        let code = "123456"

        beforeEach {
            transaction = BaseAuthTransaction(redirectURL: self.RedirectURL,
                                              state: "state",
                                              handler: handler,
                                              logger: nil,
                                              finish: callback)
            result = nil
            stub(condition: isToken(self.Domain.host!) && hasAtLeast(["code": code,
                                                                 "code_verifier": generator.verifier,
                                                                 "grant_type": "authorization_code",
                                                                 "redirect_uri": self.RedirectURL.absoluteString])) {
                _ in return authResponse(accessToken: "AT", idToken: idToken)
            }
            stub(condition: isJWKSPath(self.Domain.host!)) { _ in jwksResponse() }
        }
        
        afterEach {
            OHHTTPStubs.removeAllStubs()
        }

        describe("code exchange") {
            context("handle url") {
                it("should handle url") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)&state=state")!
                    expect(transaction.handleUrl(url)) == true
                    expect(result).toEventually(haveCredentials())
                }

                it("should handle url with error") {
                    let url = URL(string: "https://samples.auth0.com/callback?error=error&error_description=description&state=state")!
                    expect(transaction.handleUrl(url)) == true
                    expect(result).toEventually(haveAuthenticationError(code: "error", description: "description"))
                }

                it("should fail to handle url without state") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)")!
                    expect(transaction.handleUrl(url)) == false
                }
            }
            
            context("cancel") {
                it("should cancel current session") {
                    transaction.cancel()
                    expect(result).to(beFailure())
                }
            }
        }
    }

}
