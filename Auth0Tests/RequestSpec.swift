import Foundation
import Quick
import Nimble

@testable import Auth0

private let url = URL(string: "https://samples.auth0.com")!

class RequestSpec: QuickSpec {
    override func spec() {

        describe("create and update request") {

            it("should create a request with headers") {
                let request = Request(session: URLSession.shared, url: url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry())
                expect(request.headers["foo"]) == "bar"
            }

            it("should create a new request with extra headers") {
                let request = Request(session: URLSession.shared, url: url, method: "GET", handle: plainJson, logger: nil, telemetry: Telemetry()).headers(["foo": "bar"])
                expect(request.headers["foo"]) == "bar"
            }

            it("should merge extra headers with existing headers") {
                let request = Request(session: URLSession.shared, url: url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry()).headers(["baz": "qux"])
                expect(request.headers["foo"]) == "bar"
                expect(request.headers["baz"]) == "qux"
            }

            it("should overwrite existing headers with extra headers") {
                let request = Request(session: URLSession.shared, url: url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry()).headers(["foo": "baz"])
                expect(request.headers["foo"]) == "baz"
            }

            it("should create a new request and not mutate an existing request") {
                let request = Request(session: URLSession.shared, url: url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry())
                expect(request.headers(["foo": "baz"]).headers["foo"]) == "baz"
                expect(request.headers["foo"]) == "bar"
            }
            
        }
    }
}
