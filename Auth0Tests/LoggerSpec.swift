// LoggerSpec.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
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
