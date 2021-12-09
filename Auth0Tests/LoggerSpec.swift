import Foundation
import Quick
import Nimble

@testable import Auth0

class LoggerSpec: QuickSpec {

    override func spec() {

        it("should build with default output") {
            let logger = DefaultLogger()
            expect(logger.output as? DefaultOutput).toNot(beNil())
        }

        var logger: Logger!
        var output: MockOutput!

        beforeEach {
            output = MockOutput()
            logger = DefaultLogger(output: output)
        }

        describe("request") {

            var request: URLRequest!

            beforeEach {
                request = URLRequest(url: URL(string: "https://auth0.com")!)
                request.httpMethod = "POST"
                request.allHTTPHeaderFields = ["Content-Type": "application/json"]
            }

            it("should log request basic info") {
                logger.trace(request: request, session: URLSession.shared)
                expect(output.messages.first) == "POST https://auth0.com HTTP/1.1"
            }

            it("should log request header") {
                logger.trace(request: request, session: URLSession.shared)
                expect(output.messages).to(contain("Content-Type: application/json"))
            }

            it("should log additional request header") {
                let sessionConfig = URLSession.shared.configuration
                sessionConfig.httpAdditionalHeaders = ["Accept": "application/json"]
                let urlSession = URLSession(configuration: sessionConfig)
                logger.trace(request: request, session: urlSession)
                expect(output.messages).to(contain("Accept: application/json"))
            }

            it("should log request body") {
                let json = "{key: \"\(UUID().uuidString)\"}"
                request.httpBody = json.data(using: .utf8)
                logger.trace(request: request, session: URLSession.shared)
                expect(output.messages).to(contain(json))
            }

        }

        describe("response") {

            var response: HTTPURLResponse!

            beforeEach {
                response = HTTPURLResponse(url: URL(string: "https://auth0.com")!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
            }

            it("should log response basic info") {
                logger.trace(response: response, data: nil)
                expect(output.messages.first) == "HTTP/1.1 200"
            }

            it("should log response header") {
                logger.trace(response: response, data: nil)
                expect(output.messages).to(contain("Content-Type: application/json"))
            }

            it("should log response body") {
                let json = "{key: \"\(UUID().uuidString)\"}"
                logger.trace(response: response, data: json.data(using: .utf8))
                expect(output.messages).to(contain(json))
            }

            it("should log nothing for non http response") {
                let response = URLResponse()
                logger.trace(response: response, data: nil)
                expect(output.messages).to(beEmpty())
            }

        }

        describe("url") {

            it("should log url") {
                logger.trace(url: URL(string: "https://samples.auth0.com/callback")!, source: nil)
                expect(output.messages.first) == "URL: https://samples.auth0.com/callback"
            }

            it("should log url with source") {
                logger.trace(url: URL(string: "https://samples.auth0.com/callback")!, source: "Safari")
                expect(output.messages.first) == "Safari: https://samples.auth0.com/callback"
            }

        }
    }
}

class MockOutput: LoggerOutput {
    var messages: [String] = []

    func log(message: String) {
        messages.append(message)
    }

    func newLine() { }
}
