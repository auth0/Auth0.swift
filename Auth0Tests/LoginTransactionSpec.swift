import Foundation
import Quick
import Nimble

@testable import Auth0

class LoginTransactionSpec: QuickSpec {

    override func spec() {
        var transaction: LoginTransaction!
        var userAgent: SpyUserAgent!
        var handler: SpyGrant!
        var loggerOutput: SpyOutput!
        let code = "123456"

        beforeEach {
            userAgent = SpyUserAgent()
            handler = SpyGrant()
            loggerOutput = SpyOutput()
            
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

                it("should fail to handle url with invalid prefix") {
                    let url = URL(string: "https://invalid.auth0.com/callback?code=\(code)&state=state")!
                    let expectedError = WebAuthError(code: .unknown("Invalid callback URL: \(url.absoluteString)"))
                    expect(transaction.resume(url)) == false
                    expect(userAgent.result).to(haveWebAuthError(expectedError))
                    expect(transaction.userAgent).to(beNil())
                }

                it("should succeed when using bundle schema") {
                    // NOTE: Interpolated so other schemes can run this test
                    let bundleId = Bundle.main.bundleIdentifier ?? ""
                    let url = URL(string: "\(bundleId).auth0://samples.auth0.com/callback?code=\(code)&state=state")!
                    let items = ["code": code, "state": "state"]
                    expect(transaction.resume(url)) == true
                    expect(handler.items) == items
                    expect(loggerOutput.messages.first).to(contain([url.absoluteString, "Callback URL"]))
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
