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

            var request: NSMutableURLRequest!

            beforeEach {
                request = NSMutableURLRequest(URL: NSURL(string: "https://auth0.com")!)
                request.HTTPMethod = "POST"
                request.allHTTPHeaderFields = ["Content-Type": "application/json"]
            }

            it("should log request basic info") {
                logger.trace(request, session: NSURLSession.sharedSession())
                expect(output.messages.first) == "POST https://auth0.com HTTP/1.1"
            }

            it("should log request header") {
                logger.trace(request, session: NSURLSession.sharedSession())
                expect(output.messages).to(contain("Content-Type: application/json"))
            }

            it("should log request body") {
                let json = "{key: \"\(NSUUID().UUIDString)\"}"
                request.HTTPBody = json.dataUsingEncoding(NSUTF8StringEncoding)
                logger.trace(request, session: NSURLSession.sharedSession())
                expect(output.messages).to(contain(json))
            }

            it("should log nothing without URL") {
                let request = NSURLRequest()
                logger.trace(request, session: NSURLSession.sharedSession())
                expect(output.messages).to(beEmpty())
            }

        }

        describe("response") {

            var response: NSURLResponse!

            beforeEach {
                response = NSHTTPURLResponse(URL: NSURL(string: "https://auth0.com")!, statusCode: 200, HTTPVersion: nil, headerFields: ["Content-Type": "application/json"])
            }

            it("should log response basic info") {
                logger.trace(response, data: nil)
                expect(output.messages.first) == "HTTP/1.1 200"
            }

            it("should log response header") {
                logger.trace(response, data: nil)
                expect(output.messages).to(contain("Content-Type: application/json"))
            }

            it("should log response body") {
                let json = "{key: \"\(NSUUID().UUIDString)\"}"
                logger.trace(response, data: json.dataUsingEncoding(NSUTF8StringEncoding))
                expect(output.messages).to(contain(json))
            }

            it("should log nothing for non http response") {
                let response = NSURLResponse()
                logger.trace(response, data: nil)
                expect(output.messages).to(beEmpty())
            }

        }

        describe("url") {

            it("should log url") {
                logger.trace(NSURL(string: "https://samples.auth0.com/callback")!, source: nil)
                expect(output.messages.first) == "URL: https://samples.auth0.com/callback"
            }

            it("should log url with source") {
                logger.trace(NSURL(string: "https://samples.auth0.com/callback")!, source: "Safari")
                expect(output.messages.first) == "Safari: https://samples.auth0.com/callback"
            }

        }
    }
}

class MockOutput: LoggerOutput {
    var messages: [String] = []

    func message(message: String) {
        messages.append(message)
    }

    func newLine() { }
}