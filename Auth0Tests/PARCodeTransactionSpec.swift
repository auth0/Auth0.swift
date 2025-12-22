import Foundation
import Quick
import Nimble

@testable import Auth0

class PARCodeTransactionSpec: QuickSpec {

    override class func spec() {
        var transaction: PARCodeTransaction!
        var userAgent: SpyUserAgent!
        var loggerOutput: SpyOutput!
        var callbackResult: WebAuthResult<AuthorizationCode>?
        
        let redirectURL = URL(string: "https://samples.auth0.com/callback")!
        let code = "test_authorization_code_123"
        let state = "test_state_456"

        beforeEach {
            userAgent = SpyUserAgent()
            loggerOutput = SpyOutput()
            callbackResult = nil
        }
        
        afterEach {
            loggerOutput.messages.removeAll()
        }

        describe("PAR code transaction") {
            
            beforeEach {
                transaction = PARCodeTransaction(
                    redirectURL: redirectURL,
                    userAgent: userAgent,
                    logger: DefaultLogger(output: loggerOutput),
                    callback: { callbackResult = $0 }
                )
            }
            
            context("successful callback") {
                
                it("should return authorization code with state") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)&state=\(state)")!
                    
                    expect(transaction.resume(url)) == true
                    expect(callbackResult).toNot(beNil())
                    
                    if case .success(let authCode) = callbackResult {
                        expect(authCode.code) == code
                        expect(authCode.state) == state
                    } else {
                        fail("Expected success result")
                    }
                    
                    expect(loggerOutput.messages.first).to(contain([url.absoluteString, "Callback URL"]))
                    expect(transaction.userAgent).to(beNil())
                }
                
                it("should return authorization code without state") {
                    let url = URL(string: "https://samples.auth0.com/callback?code=\(code)")!
                    
                    expect(transaction.resume(url)) == true
                    expect(callbackResult).toNot(beNil())
                    
                    if case .success(let authCode) = callbackResult {
                        expect(authCode.code) == code
                        expect(authCode.state).to(beNil())
                    } else {
                        fail("Expected success result")
                    }
                    
                    expect(transaction.userAgent).to(beNil())
                }
            }
            
            context("error handling") {
                
                it("should handle error response from Auth0") {
                    let url = URL(string: "https://samples.auth0.com/callback?error=access_denied&error_description=User%20cancelled&state=\(state)")!
                    
                    expect(transaction.resume(url)) == true
                    expect(callbackResult).toNot(beNil())
                    
                    if case .failure(let error) = callbackResult {
                        expect(error.code) == WebAuthError.Code.other
                        expect(error.cause).toNot(beNil())
                    } else {
                        fail("Expected failure result")
                    }
                    
                    expect(transaction.userAgent).to(beNil())
                }
                
                it("should fail when code is missing") {
                    let url = URL(string: "https://samples.auth0.com/callback?state=\(state)")!
                    
                    expect(transaction.resume(url)) == true
                    expect(callbackResult).toNot(beNil())
                    
                    if case .failure(let error) = callbackResult {
                        expect(error.code) == WebAuthError.Code.noAuthorizationCode(["state": state])
                    } else {
                        fail("Expected failure result")
                    }
                    
                    expect(transaction.userAgent).to(beNil())
                }
                
                it("should fail on invalid callback URL") {
                    let url = URL(string: "https://other.domain.com/callback?code=\(code)&state=\(state)")!
                    
                    expect(transaction.resume(url)) == false
                    expect(callbackResult).to(beNil())
                    expect(transaction.userAgent).to(beNil())
                }
            }
            
            context("cancel") {
                
                it("should cancel transaction and return user cancelled error") {
                    transaction.cancel()
                    
                    expect(transaction.userAgent).to(beNil())
                    expect(userAgent.result).toNot(beNil())
                    
                    if case .failure(let error) = userAgent.result {
                        expect(error.code) == WebAuthError.Code.userCancelled
                    } else {
                        fail("Expected failure result")
                    }
                }
            }
        }
    }

}
