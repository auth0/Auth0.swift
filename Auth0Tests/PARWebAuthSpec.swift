import Foundation
import Quick
import Nimble
import Combine

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
                        expect(error) == WebAuthError(code: .invalidRequestUri(InvalidRequestUri))
                    } else {
                        fail("Expected invalidRequestUri error")
                    }
                }

                it("should fail with empty request_uri") {
                    var result: WebAuthResult<AuthorizationCode>?
                    let par = newPARWebAuth()
                    par.start(requestUri: "") { result = $0 }
                    if case .failure(let error) = result {
                        expect(error) == WebAuthError(code: .invalidRequestUri(""))
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
                        expect(error) == WebAuthError(code: .noAuthorizationCode(["state": "some-state"]))
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

        // MARK: - Combine API

        describe("Combine API") {
            var cancellables: Set<AnyCancellable>!

            beforeEach {
                cancellables = []
            }

            afterEach {
                cancellables.removeAll()
                TransactionStore.shared.clear()
            }

            it("should publish error on invalid request_uri") {
                waitUntil { done in
                    let par = newPARWebAuth()
                    par.start(requestUri: InvalidRequestUri)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                expect(error) == WebAuthError(code: .invalidRequestUri(InvalidRequestUri))
                                done()
                            }
                        }, receiveValue: { _ in
                            fail("Should not emit authorization code")
                        })
                        .store(in: &cancellables)
                }
            }

            it("should publish error on user cancellation") {
                waitUntil { done in
                    let par = newPARWebAuth()
                        .provider { url, callback in
                            callback(.failure(WebAuthError(code: .userCancelled)))
                            return SpyUserAgent()
                        }
                    par.start(requestUri: ValidRequestUri)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                expect(error) == WebAuthError.userCancelled
                                done()
                            }
                        }, receiveValue: { _ in
                            fail("Should not emit authorization code")
                        })
                        .store(in: &cancellables)
                }
            }
        }

        // MARK: - Async/Await API

        describe("Async/Await API") {

            afterEach {
                TransactionStore.shared.clear()
            }

            it("should throw error on invalid request_uri") {
                waitUntil { done in
                    Task {
                        do {
                            let par = newPARWebAuth()
                            _ = try await par.start(requestUri: InvalidRequestUri)
                            fail("Should have thrown an error")
                        } catch let error as WebAuthError {
                            expect(error) == WebAuthError(code: .invalidRequestUri(InvalidRequestUri))
                            done()
                        } catch {
                            fail("Unexpected error type: \(error)")
                        }
                    }
                }
            }

            it("should throw error on user cancellation") {
                waitUntil { done in
                    Task {
                        do {
                            let par = newPARWebAuth()
                                .provider { url, callback in
                                    callback(.failure(WebAuthError(code: .userCancelled)))
                                    return SpyUserAgent()
                                }
                            _ = try await par.start(requestUri: ValidRequestUri)
                            fail("Should have thrown an error")
                        } catch let error as WebAuthError {
                            expect(error) == WebAuthError.userCancelled
                            done()
                        } catch {
                            fail("Unexpected error type: \(error)")
                        }
                    }
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
