import Foundation
import Quick
import Nimble

@testable import Auth0

private let ClientId = "ClientId"
private let Domain = "samples.auth0.com"
private let DomainURL = URL.httpsURL(from: Domain)
private let ValidRequestUri = "urn:ietf:params:oauth:request_uri:abc123"
private let InvalidRequestUri = "invalid-request-uri"
private let Code = "auth_code_456"

private func newPARWebAuth(barrier: Barrier = MockPARBarrier()) -> PARWebAuth {
    return PARWebAuth(clientId: ClientId,
                      url: DomainURL,
                      storage: TransactionStore.shared,
                      barrier: barrier)
}

class PARWebAuthSpec: QuickSpec {

    override class func spec() {

        afterEach {
            TransactionStore.shared.clear()
        }

        describe("start") {

            context("validation") {
                it("should fail with invalid request_uri") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                    par.start(requestUri: InvalidRequestUri) { result = $0 }
                    expect(result).toNot(beNil())
                    if case .failure(let error) = result {
                        expect(error) == WebAuthError.invalidRequestUri
                    } else {
                        fail("Expected invalidRequestUri error")
                    }
                }

                it("should fail with empty request_uri") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                    par.start(requestUri: "") { result = $0 }
                    if case .failure(let error) = result {
                        expect(error) == WebAuthError.invalidRequestUri
                    } else {
                        fail("Expected invalidRequestUri error")
                    }
                }

                it("should fail when transaction is already active") {
                    let barrier = BlockingPARBarrier()
                    let par = newPARWebAuth(barrier: barrier)
                    var result: WebAuthResult<AuthorizationCode>?
                    par.start(requestUri: ValidRequestUri) { result = $0 }
                    if case .failure(let error) = result {
                        expect(error) == WebAuthError.transactionActiveAlready
                    } else {
                        fail("Expected transactionActiveAlready error")
                    }
                }
            }

            context("authorize URL") {
                it("should open browser with correct authorize URL") {
                    var capturedURL: URL?
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            capturedURL = url
                            return SpyUserAgent()
                        }
                    par.start(requestUri: ValidRequestUri) { _ in }
                    expect(capturedURL).toEventuallyNot(beNil())
                    let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: true)!
                    expect(components.scheme) == "https"
                    expect(components.host) == Domain
                    expect(components.path) == "/authorize"
                    expect(components.queryItems).to(containItem(withName: "client_id", value: ClientId))
                    expect(components.queryItems).to(containItem(withName: "request_uri", value: ValidRequestUri))
                }

                it("should include session_transfer_token in authorize URL") {
                    var capturedURL: URL?
                    let par = newPARWebAuth()
                        .sessionTransferToken("sst_token_value")
                        .provider { url, callback in
                            capturedURL = url
                            return SpyUserAgent()
                        }
                    par.start(requestUri: ValidRequestUri) { _ in }
                    expect(capturedURL).toEventuallyNot(beNil())
                    let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: true)!
                    expect(components.queryItems).to(containItem(withName: "session_transfer_token", value: "sst_token_value"))
                }

                it("should not include session_transfer_token when not set") {
                    var capturedURL: URL?
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            capturedURL = url
                            return SpyUserAgent()
                        }
                    par.start(requestUri: ValidRequestUri) { _ in }
                    expect(capturedURL).toEventuallyNot(beNil())
                    let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: true)!
                    let sstItems = components.queryItems?.filter { $0.name == "session_transfer_token" }
                    expect(sstItems).to(beEmpty())
                }
            }

            context("callback handling") {
                it("should return authorization code on successful redirect") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            return PARMockUserAgent(callback: callback)
                        }
                    par.start(requestUri: ValidRequestUri) { result = $0 }

                    let callbackURL = URL(string: "com.auth0.samples://samples.auth0.com/ios/com.auth0.samples/callback?code=\(Code)")!
                    _ = TransactionStore.shared.resume(callbackURL)

                    expect(result).toEventuallyNot(beNil())
                    if case .success(let authCode) = result {
                        expect(authCode.code) == Code
                    } else {
                        fail("Expected success with authorization code")
                    }
                }

                it("should return authorization code with state from redirect") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            return PARMockUserAgent(callback: callback)
                        }
                    par.start(requestUri: ValidRequestUri) { result = $0 }

                    let callbackURL = URL(string: "com.auth0.samples://samples.auth0.com/ios/com.auth0.samples/callback?code=\(Code)&state=par-state")!
                    _ = TransactionStore.shared.resume(callbackURL)

                    expect(result).toEventuallyNot(beNil())
                    if case .success(let authCode) = result {
                        expect(authCode.code) == Code
                        expect(authCode.state) == "par-state"
                    } else {
                        fail("Expected success with authorization code and state")
                    }
                }

                it("should return error when redirect contains error") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            return PARMockUserAgent(callback: callback)
                        }
                    par.start(requestUri: ValidRequestUri) { result = $0 }

                    let callbackURL = URL(string: "com.auth0.samples://samples.auth0.com/ios/com.auth0.samples/callback?error=access_denied&error_description=Unauthorized")!
                    _ = TransactionStore.shared.resume(callbackURL)

                    expect(result).toEventuallyNot(beNil())
                    if case .failure(let error) = result {
                        expect(error.cause).toNot(beNil())
                    } else {
                        fail("Expected failure result")
                    }
                }

                it("should return error when redirect is missing code") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            return PARMockUserAgent(callback: callback)
                        }
                    par.start(requestUri: ValidRequestUri) { result = $0 }

                    let callbackURL = URL(string: "com.auth0.samples://samples.auth0.com/ios/com.auth0.samples/callback?state=some-state")!
                    _ = TransactionStore.shared.resume(callbackURL)

                    expect(result).toEventuallyNot(beNil())
                    if case .failure(let error) = result {
                        expect(error) == WebAuthError.noAuthorizationCode
                    } else {
                        fail("Expected noAuthorizationCode error")
                    }
                }
            }

            context("user cancellation") {
                it("should return user cancelled error when provider reports cancellation") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            callback(.failure(WebAuthError(code: .userCancelled)))
                            return SpyUserAgent()
                        }
                    par.start(requestUri: ValidRequestUri) { result = $0 }
                    expect(result).toEventuallyNot(beNil())
                    if case .failure(let error) = result {
                        expect(error) == WebAuthError.userCancelled
                    } else {
                        fail("Expected userCancelled error")
                    }
                }
            }

            context("builder methods") {
                it("should return self for chaining") {
                    let par = newPARWebAuth()
                    let result = par
                        .sessionTransferToken("token")
                        .useEphemeralSession()
                    expect(result) === par
                }
            }
        }
    }

}

// MARK: - Test Helpers

private class MockPARBarrier: Barrier {
    func raise() -> Bool { return true }
    func lower() {}
}

private class BlockingPARBarrier: Barrier {
    func raise() -> Bool { return false }
    func lower() {}
}

private class PARMockUserAgent: WebAuthUserAgent {
    let callback: WebAuthProviderCallback

    init(callback: @escaping WebAuthProviderCallback) {
        self.callback = callback
    }

    func start() {}

    func finish(with result: WebAuthResult<Void>) {
        self.callback(result)
    }
}
