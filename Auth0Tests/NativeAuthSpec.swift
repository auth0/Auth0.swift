// NativeAuthSpec.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
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
import SafariServices
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"
private let DomainURL = URL(fileURLWithPath: Domain)
private let Connection = "facebook"
private let Scope = "openid"
private let Parameters: [String: Any] = [:]
private let Timeout: DispatchTimeInterval = .seconds(2)
private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let FacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let InvalidFacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = generateJWT().string

class MockNativeAuthTransaction: NativeAuthTransaction {
    var connection: String
    var scope: String
    var parameters: [String : Any]
    var authentication: Authentication

    init(connection: String, scope: String, parameters: [String: Any], authentication: Authentication) {
        self.connection = connection
        self.scope = scope
        self.parameters = parameters
        self.authentication = authentication
    }

    var delayed: NativeAuthTransaction.Callback = { _ in }

    func auth(callback: @escaping NativeAuthTransaction.Callback) {
        self.delayed = callback
    }

    func cancel() {
        self.delayed(.failure(WebAuthError.userCancelled))
        self.delayed = { _ in }
    }

    func resume(_ url: URL) -> Bool {
        self.delayed(self.onNativeAuth())
        self.delayed = { _ in }
        return true
    }

    /// Test Hooks
    var onNativeAuth: () -> Result<NativeAuthCredentials> = {
        return .success(NativeAuthCredentials(token: FacebookToken, extras: [:]))
    }
}

class NativeAuthSpec: QuickSpec {

    override func spec() {

        var nativeTransaction: MockNativeAuthTransaction!
        let authentication = Auth0Authentication(clientId: ClientId, url: URL(string: "https://\(Domain)")!)

        beforeEach {
            stub(condition: isHost(Domain)) { _ in
                return HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                }.name = "YOU SHALL NOT PASS!"

            nativeTransaction = MockNativeAuthTransaction(connection: Connection , scope: Scope, parameters: Parameters, authentication: authentication)
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("Initializer values set") {

            it("should have connection") {
                expect(nativeTransaction.connection) == Connection
            }

            it("should have scope") {
                expect(nativeTransaction.scope) == Scope
            }

            it("should have empty parameters") {
                expect(nativeTransaction.parameters).to(haveCount(0))
            }
        }

        describe("start") {

            beforeEach {
                stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token":FacebookToken, "connection": "facebook", "scope": "openid"])) { _ in return authResponse(accessToken: AccessToken, idToken: IdToken) }.name = "Facebook Auth OpenID"
                stub(condition: isOAuthAccessToken(Domain) && hasAtLeast(["access_token":InvalidFacebookToken, "connection": "facebook", "scope": "openid"])) { _ in return authFailure(error: "invalid_token", description: "invalid_token") }.name = "invalid token"
            }

            it("should store transaction in store") {
                nativeTransaction.start { _ in }
                expect(TransactionStore.shared.current?.state) == nativeTransaction.state
            }

            it("should nil transaction in store after resume") {
                nativeTransaction.start { _ in }
                #if os(iOS)
                _ = Auth0.resumeAuth(DomainURL, options: [:])
                #else
                _ = Auth0.resumeAuth([DomainURL])
                #endif
                expect(TransactionStore.shared.current).to(beNil())
            }

            it("should yield credentials on success") {
                waitUntil(timeout: Timeout) { done in
                    nativeTransaction
                        .start { result in
                        switch result {
                        case .success(let result):
                            expect(result.accessToken) == AccessToken
                            done()
                        default:
                            break
                        }
                    }
                    _ = nativeTransaction.resume(DomainURL)
                }

            }

            it("should yield error on native auth failure") {
                nativeTransaction.onNativeAuth =  {
                    return .failure(WebAuthError.missingAccessToken)
                }
                waitUntil(timeout: Timeout) { done in
                    nativeTransaction.start { result in
                        switch result {
                        case .failure(let error):
                            expect(error).to(matchError(WebAuthError.missingAccessToken))
                            done()
                        default:
                            break
                        }
                    }
                    _ = nativeTransaction.resume(DomainURL)
                }

            }

            it("should yield auth error on invalid native access token") {
                nativeTransaction.onNativeAuth = {
                    return .success(NativeAuthCredentials(token: InvalidFacebookToken, extras: [:]))
                }
                waitUntil(timeout: Timeout) { done in
                    nativeTransaction.start { result in
                        expect(result).to(haveAuthenticationError(code: "invalid_token", description: "invalid_token"))
                        done()
                    }
                    _ = nativeTransaction.resume(DomainURL)
                }

            }
        }

        describe("cancel") {

            it("should yield error on cancel") {
                waitUntil(timeout: Timeout) { done in
                    nativeTransaction.start { result in
                        switch result {
                        case .failure(let error):
                            expect(error).to(matchError(WebAuthError.userCancelled))
                            done()
                        default:
                            break
                        }
                    }
                    nativeTransaction.cancel()
                }
                
            }
            
        }
        
    }
    
}



