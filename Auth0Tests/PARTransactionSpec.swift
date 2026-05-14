import Foundation
import Quick
import Nimble

@testable import Auth0

class PARTransactionSpec: QuickSpec {

    override class func spec() {
        var transaction: PARTransaction!
        let userAgent = SpyUserAgent()
        let redirectURL = URL(string: "https://samples.auth0.com/callback")!
        let code = "auth_code_123"

        describe("PAR transaction") {

            context("resume with code") {
                it("should return authorization code") {
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)")!
                    expect(transaction.resume(url)) == true
                    expect(result).toNot(beNil())
                    if case .success(let authCode) = result {
                        expect(authCode.code) == code
                        expect(authCode.state).to(beNil())
                    } else {
                        fail("Expected success result")
                    }
                    expect(transaction.userAgent).to(beNil())
                }

                it("should return authorization code with state from redirect") {
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)&state=test-state")!
                    expect(transaction.resume(url)) == true
                    if case .success(let authCode) = result {
                        expect(authCode.code) == code
                        expect(authCode.state) == "test-state"
                    } else {
                        fail("Expected success result")
                    }
                }
            }

            context("resume with error") {
                it("should handle error response") {
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?error=access_denied&error_description=Unauthorized")!
                    expect(transaction.resume(url)) == true
                    expect(transaction.userAgent).to(beNil())
                    if case .failure(let error) = result {
                        expect(error.cause).toNot(beNil())
                    } else {
                        fail("Expected failure result")
                    }
                }

                it("should handle error response without description") {
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?error=server_error")!
                    expect(transaction.resume(url)) == true
                    if case .failure = result {
                        // Expected
                    } else {
                        fail("Expected failure result")
                    }
                }
            }

            context("resume with missing code") {
                it("should fail when code is missing from callback") {
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?state=some-state")!
                    expect(transaction.resume(url)) == true
                    expect(transaction.userAgent).to(beNil())
                    if case .failure(let error) = result {
                        expect(error) == WebAuthError(code: .noAuthorizationCode(["state": "some-state"]))
                    } else {
                        fail("Expected failure result")
                    }
                }
            }

            context("resume with invalid URL") {
                it("should fail for URL without query parameters") {
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "foo")!
                    expect(transaction.resume(url)) == false
                    expect(transaction.userAgent).to(beNil())
                }
            }

            context("cancel") {
                it("should cancel current transaction") {
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    transaction.cancel()
                    expect(transaction.userAgent).to(beNil())
                    expect(userAgent.result).to(haveWebAuthError(WebAuthError(code: .userCancelled)))
                }
            }
        }
    }

}
