// ResponseSpec.swift
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

private let URL = NSURL(string: "https://samples.auth0.com")!
private let JSONData = try! NSJSONSerialization.dataWithJSONObject(["attr": "value"], options: [])

private func http(statusCode: Int, url: NSURL = URL) -> NSHTTPURLResponse {
    return NSHTTPURLResponse(URL: url, statusCode: statusCode, HTTPVersion: "1.0", headerFields: [:])!
}

class ResponseSpec: QuickSpec {
    override func spec() {

        describe("successful response") {

            it("should handle HTTP 204 responses") {
                let response = Response(data: nil, response: http(204), error: nil)
                expect(response.result).to(beSuccessful())
            }

            it("should handle valid JSON") {
                let response = Response(data: JSONData, response: http(200), error: nil)
                expect(response.result).to(beSuccessful())
            }

            it("should handle string as json for reset password") {
                let data = "A simple String".dataUsingEncoding(NSUTF8StringEncoding)
                let response = Response(data: data, response: http(200, url: NSURL(string: "https://samples.auth0.com/dbconnections/change_password")!), error: nil)
                expect(response.result).to(beSuccessful())
            }
        }

        describe("failed response") {

            it("should fail with code lesser than 200") {
                let response = Response(data: nil, response: http(199), error: nil)
                expect(response.result).toNot(beSuccessful())
            }

            it("should fail with code greater than 200") {
                let response = Response(data: nil, response: http(300), error: nil)
                expect(response.result).toNot(beSuccessful())
            }

            it("should fail with empty HTTP 200 responses") {
                let response = Response(data: nil, response: http(200), error: nil)
                expect(response.result).toNot(beSuccessful())
            }

            it("should fail with invalid JSON") {
                let data = "A simple String".dataUsingEncoding(NSUTF8StringEncoding)
                let response = Response(data: data, response: http(200), error: nil)
                expect(response.result).toNot(beSuccessful())
            }

            it("should fail with NSError") {
                let error = NSError(domain: "com.auth0", code: -99999, userInfo: nil)
                let response = Response(data: nil, response: http(200), error: error)
                expect(response.result).toNot(beSuccessful())
            }

        }
    }
}

private func beSuccessful() -> MatcherFunc<Response.Result> {
    return MatcherFunc { expression, failureMessage in
        failureMessage.postfixMessage = "be a successful response"
        if let actual = try expression.evaluate(), case .Success = actual {
            return true
        }
        return false
    }
}