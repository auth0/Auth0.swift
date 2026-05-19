import Foundation
import Quick
import Nimble

@testable import Auth0

class PARTransactionSpec: QuickSpec {

    override class func spec() {
        var transaction: PARTransaction!
        let redirectURL = URL(string: "https://samples.auth0.com/callback")!
        let code = "auth_code_123"

        describe("PAR transaction") {

            context("resume") {
                it("should return authorization code") {
                    let userAgent = SpyUserAgent()
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)")!
                    expect(transaction.resume(url)) == true
                    expect(result).toEventuallyNot(beNil())
                    if case .success(let authCode) = result {
                        expect(authCode.code) == code
                        expect(authCode.state).to(beNil())
                    } else {
                        fail("Expected success result")
                    }
                    expect(transaction.userAgent).to(beNil())
                }

                it("should return authorization code with state from redirect") {
                    let userAgent = SpyUserAgent()
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)&state=test-state")!
                    expect(transaction.resume(url)) == true
                    expect(result).toEventuallyNot(beNil())
                    if case .success(let authCode) = result {
                        expect(authCode.code) == code
                        expect(authCode.state) == "test-state"
                    } else {
                        fail("Expected success result")
                    }
                }

                it("should handle url with error") {
                    let userAgent = SpyUserAgent()
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?error=access_denied&error_description=Unauthorized")!
                    let errorInfo = ["error": "access_denied", "error_description": "Unauthorized"]
                    let expectedError = WebAuthError(code: .other, cause: AuthenticationError(info: errorInfo, statusCode: 302))
                    expect(transaction.resume(url)) == true
                    expect(userAgent.result).to(haveWebAuthError(expectedError))
                    expect(transaction.userAgent).to(beNil())
                    expect(result).toEventually(haveWebAuthError(expectedError))
                }

                it("should handle error response without description") {
                    let userAgent = SpyUserAgent()
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?error=server_error")!
                    let errorInfo = ["error": "server_error"]
                    let expectedError = WebAuthError(code: .other, cause: AuthenticationError(info: errorInfo, statusCode: 302))
                    expect(transaction.resume(url)) == true
                    expect(transaction.userAgent).to(beNil())
                    expect(result).toEventually(haveWebAuthError(expectedError))
                }

                it("should fail when code is missing from callback") {
                    let userAgent = SpyUserAgent()
                    var result: WebAuthResult<AuthorizationCode>?
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { result = $0 })
                    let url = URL(string: "https://samples.auth0.com/callback?state=some-state")!
                    let expectedError = WebAuthError(code: .noAuthorizationCode(["state": "some-state"]))
                    expect(transaction.resume(url)) == true
                    expect(transaction.userAgent).to(beNil())
                    expect(result).toEventually(haveWebAuthError(expectedError))
                }

                it("should fail to handle invalid url") {
                    let userAgent = SpyUserAgent()
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { _ in })
                    let url = URL(string: "foo")!
                    let expectedError = WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))
                    expect(transaction.resume(url)) == false
                    expect(userAgent.result).to(haveWebAuthError(expectedError))
                    expect(transaction.userAgent).to(beNil())
                }
            }

            context("cancel") {
                it("should cancel current transaction") {
                    let userAgent = SpyUserAgent()
                    transaction = PARTransaction(redirectURL: redirectURL,
                                                  userAgent: userAgent,
                                                  callback: { _ in })
                    transaction.cancel()
                    expect(transaction.userAgent).to(beNil())
                    expect(userAgent.result).to(haveWebAuthError(WebAuthError(code: .userCancelled)))
                }
            }
        }
    }

}
