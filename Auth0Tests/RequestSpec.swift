import Foundation
import Combine
import Quick
import Nimble
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

private let Url = URL(string: "https://samples.auth0.com")!
private let Timeout: NimbleTimeInterval = .seconds(2)

fileprivate extension Request where T == [String: Any], E == AuthenticationError {

    init(session: URLSession = .shared,
         url: URL = Url,
         method: String = "GET",
         parameters: [String: Any] = [:],
         headers: [String: String] = [:]) {
        self.init(session: session,
                  url: url,
                  method: method,
                  handle: plainJson,
                  parameters: parameters,
                  headers: headers,
                  logger: nil,
                  telemetry: Telemetry())
    }

}

class RequestSpec: QuickSpec {
    override func spec() {

        beforeEach {
            stub(condition: isHost(Url.host!)) { _ in catchAllResponse() }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("create and update request") {

            context("parameters") {

                it("should create a request with parameters") {
                    let request = Request(parameters: ["foo": "bar"])
                    expect(request.parameters["foo"] as? String) == "bar"
                }

                it("should create a new request with extra parameters") {
                    let request = Request().parameters(["foo": "bar"])
                    expect(request.parameters["foo"] as? String) == "bar"
                }

                it("should merge extra parameters with existing parameters") {
                    let request = Request(parameters: ["foo": "bar"]).parameters(["baz": "qux"])
                    expect(request.parameters["foo"] as? String) == "bar"
                    expect(request.parameters["baz"] as? String) == "qux"
                }

                it("should overwrite existing parameters with extra parameters") {
                    let request = Request(parameters: ["foo": "bar"]).parameters(["foo": "baz"])
                    expect(request.parameters["foo"] as? String) == "baz"
                }

                it("should create a new request and not mutate an existing request") {
                    let request = Request(parameters: ["foo": "bar"])
                    expect(request.parameters(["foo": "baz"]).parameters["foo"] as? String) == "baz"
                    expect(request.parameters["foo"] as? String) == "bar"
                }

                it("should enforce the openid scope when adding extra parameters") {
                    let request = Request(parameters: ["foo": "bar"])
                    expect(request.parameters(["scope": "email phone"]).parameters["scope"] as? String) == "openid email phone"
                }

                it("should add the parameters as query parameters") {
                    let request = Request(parameters: ["foo": "bar"])
                    expect(request.request.url?.query) == "foo=bar"
                }

                it("should append the parameters to the existing query parameters") {
                    let request = Request(url: URL(string: "\(Url.absoluteString)?foo=bar")!, parameters: ["baz": "qux"])
                    expect(request.request.url?.query) == "foo=bar&baz=qux"
                }

                it("should add the parameters to the request body") {
                    let request = Request(method: "POST", parameters: ["foo": "bar"])
                    let body = try! JSONSerialization.jsonObject(with: request.request.httpBody!, options: []) as! [String: Any]
                    expect(body["foo"] as? String) == "bar"
                }

                it("should not add the parameters as query parameters when the URL is malformed") {
                    let request = Request(url: URL(string: "//:foo/bar")!, parameters: ["foo": "bar"])
                   expect(request.request.url?.query).to(beNil())
                }
            }

            context("headers") {

                it("should create a request with headers") {
                    let request = Request(headers: ["foo": "bar"])
                    expect(request.headers["foo"]) == "bar"
                }

                it("should create a new request with extra headers") {
                    let request = Request().headers(["foo": "bar"])
                    expect(request.headers["foo"]) == "bar"
                }

                it("should merge extra headers with existing headers") {
                    let request = Request(headers: ["foo": "bar"]).headers(["baz": "qux"])
                    expect(request.headers["foo"]) == "bar"
                    expect(request.headers["baz"]) == "qux"
                }

                it("should overwrite existing headers with extra headers") {
                    let request = Request(headers: ["foo": "bar"]).headers(["foo": "baz"])
                    expect(request.headers["foo"]) == "baz"
                }

                it("should create a new request and not mutate an existing request") {
                    let request = Request(headers: ["foo": "bar"])
                    expect(request.headers(["foo": "baz"]).headers["foo"]) == "baz"
                    expect(request.headers["foo"]) == "bar"
                }

            }

        }

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            describe("combine") {
                var cancellables: Set<AnyCancellable> = []

                afterEach {
                    cancellables.removeAll()
                }

                it("should emit only one value") {
                    stub(condition: isHost(Url.host!)) { _ in
                        return apiSuccessResponse()
                    }
                    let request = Request()
                    await waitUntil(timeout: Timeout) { done in
                        request
                            .start()
                            .assertNoFailure()
                            .count()
                            .sink(receiveValue: { count in
                                expect(count) == 1
                                done()
                            })
                            .store(in: &cancellables)
                    }
                }

                it("should complete with the response") {
                    stub(condition: isHost(Url.host!)) { _ in
                        return apiSuccessResponse(json: ["foo": "bar"])
                    }
                    let request = Request()
                    await waitUntil(timeout: Timeout) { done in
                        request
                            .start()
                            .sink(receiveCompletion: { completion in
                                guard case .finished = completion else { return }
                                done()
                            }, receiveValue: { response in
                                expect(response).toNot(beEmpty())
                            })
                            .store(in: &cancellables)
                    }
                }

                it("should complete with an error") {
                    stub(condition: isHost(Url.host!)) { _ in
                        return apiFailureResponse()
                    }
                    let request = Request()
                    await waitUntil(timeout: Timeout) { done in
                        request
                            .start()
                            .ignoreOutput()
                            .sink(receiveCompletion: { completion in
                                guard case .failure = completion else { return }
                                done()
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    }
                }

            }
        }

        #if canImport(_Concurrency)
        describe("async await") {

            it("should return the response") {
                stub(condition: isHost(Url.host!)) { _ in
                    return apiSuccessResponse(json: ["foo": "bar"])
                }
                let request = Request()
                await waitUntil(timeout: Timeout) { done in
                    #if compiler(>=5.5.2)
                    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                        Task.init {
                            let response = try await request.start()
                            expect(response).toNot(beEmpty())
                            done()
                        }
                    }
                    #else
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                        Task.init {
                            let response = try await request.start()
                            expect(response).toNot(beEmpty())
                            done()
                        }
                    } else {
                        done()
                    }
                    #endif
                }
            }

            it("should throw an error") {
                stub(condition: isHost(Url.host!)) { _ in
                    return apiFailureResponse()
                }
                let request = Request()
                await waitUntil(timeout: Timeout) { done in
                    #if compiler(>=5.5.2)
                    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                        Task.init {
                            do {
                                _ = try await request.start()
                            } catch {
                                done()
                            }
                        }
                    }
                    #else
                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                        Task.init {
                            do {
                                _ = try await request.start()
                            } catch {
                                done()
                            }
                        }
                    } else {
                        done()
                    }
                    #endif
                }
            }

        }
        #endif

    }
}
