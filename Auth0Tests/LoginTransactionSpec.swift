import Foundation
import Quick
import Nimble

@testable import Auth0

class LoginTransactionSpec: QuickSpec {

    override func spec() {
        var transaction: LoginTransaction!
        let userAgent = SpyUserAgent()
        let handler = SpyGrant()
        let loggerOutput = SpyOutput()
        let code = "123456"

        beforeEach {
            transaction = LoginTransaction(redirectURL: URL(string: "https://samples.auth0.com/callback")!,
                                           state: "state",
                                           userAgent: userAgent,
                                           handler: handler,
                                           logger: DefaultLogger(output: loggerOutput),
                                           callback: { _ in })
        }

        describe("code exchange") {
            context("resume") {
                it("should handle url") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)&state=state")!
                    let items = ["code": code, "state": "state"]
                    expect(transaction.resume(url)) == true
                    expect(handler.items) == items
                    expect(loggerOutput.messages.first).to(contain([url.absoluteString, "Callback URL"]))
                    expect(transaction.userAgent).to(beNil())
                }

                it("should handle url with error") {
                    let url = URL(string: "https://samples.auth0.com/callback?error=error&error_description=description&state=state")!
                    let errorInfo = ["error": "error", "error_description": "description", "state": "state"]
                    let expectedError = WebAuthError(code: .other, cause: AuthenticationError(info: errorInfo))
                    expect(transaction.resume(url)) == true
                    expect(userAgent.result).to(haveWebAuthError(expectedError))
                    expect(transaction.userAgent).to(beNil())
                }

                it("should fail to handle url without state") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)")!
                    let expectedError = WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))
                    expect(transaction.resume(url)) == false
                    expect(userAgent.result).to(haveWebAuthError(expectedError))
                    expect(transaction.userAgent).to(beNil())
                }

                it("should fail to handle invalid url") {
                    let url = URL(string: "foo")!
                    let expectedError = WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))
                    expect(transaction.resume(url)) == false
                    expect(userAgent.result).to(haveWebAuthError(expectedError))
                    expect(transaction.userAgent).to(beNil())
                }
            }

            context("cancel") {
                it("should cancel current transaction") {
                    transaction.cancel()
                    expect(transaction.userAgent).to(beNil())
                }
            }
        }
    }

}
