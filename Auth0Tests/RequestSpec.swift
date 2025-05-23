import Foundation
import Combine
import Quick
import Nimble

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
    override class func spec() {

        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
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

                // See https://forums.swift.org/t/url-string-behavior-changed-with-xcode-15-0-beta-5/66570/4
                #if swift(<5.9)
                it("should not add the parameters as query parameters when the URL is malformed") {
                    let request = Request(url: URL(string: "//:invalid/url")!, parameters: ["foo": "bar"])
                   expect(request.request.url?.query).to(beNil())
                }
                #endif
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

        describe("combine") {
            var cancellables: Set<AnyCancellable> = []

            afterEach {
                cancellables.removeAll()
            }

            it("should emit only one value") {
                NetworkStub.addStub(condition: {
                    $0.isHost(Url.host!)
                }, response: apiSuccessResponse())
                let request = Request()
                waitUntil(timeout: Timeout) { done in
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
                NetworkStub.addStub(condition: {
                    $0.isHost(Url.host!)
                }, response: apiSuccessResponse(json: ["foo": "bar"]))
                let request = Request()
                waitUntil(timeout: Timeout) { done in
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
                NetworkStub.addStub(condition: {
                    $0.isHost(Url.host!)
                }, response: apiFailureResponse())
                let request = Request()
                waitUntil(timeout: Timeout) { done in
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

        #if canImport(_Concurrency)
        describe("async await") {

            it("should return the response") {
                NetworkStub.addStub(condition: {
                    $0.isHost(Url.host!)
                }, response: apiSuccessResponse(json: ["foo": "bar"]))
                let request = Request()
                waitUntil(timeout: Timeout) { done in
                    Task.init {
                        let response = try await request.start()
                        expect(response).toNot(beEmpty())
                        done()
                    }
                }
            }

            it("should throw an error") {
                NetworkStub.addStub(condition: {
                    $0.isHost(Url.host!)
                }, response: apiFailureResponse())
                let request = Request()
                waitUntil(timeout: Timeout) { done in
                    Task.init {
                        do {
                            _ = try await request.start()
                        } catch {
                            done()
                        }
                    }
                }
            }

        }
        #endif

    }
}

func plainJson(from response: Response<AuthenticationError>,
               callback: Request<[String: Any], AuthenticationError>.Callback) {
    do {
        if let dictionary = try response.result()?.body as? [String: Any] {
            callback(.success(dictionary))
        } else {
            callback(.failure(AuthenticationError(from: response)))
        }
    } catch {
        callback(.failure(error))
    }
}
