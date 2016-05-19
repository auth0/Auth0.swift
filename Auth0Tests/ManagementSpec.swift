// ManagementSpec.swift
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

private let Domain = "samples.auth0.com"
private let Token = NSUUID().UUIDString
private let DomainURL = NSURL(string: "https://\(Domain)")!

class ManagementSpec: QuickSpec {
    override func spec() {

        describe("init") {

            it("should init with token & url") {
                let management = Management(token: Token, url: DomainURL)
                expect(management).toNot(beNil())
            }

            it("should init with token, url & session") {
                let management = Management(token: Token, url: DomainURL, session: NSURLSession.sharedSession())
                expect(management).toNot(beNil())
            }

        }

        describe("object response handling") {
            let management = Management(token: Token, url: NSURL(string: "https://\(Domain)")!)

            context("success") {
                let data = "{\"key\": \"value\"}".dataUsingEncoding(NSUTF8StringEncoding)!
                let http = NSHTTPURLResponse(URL: DomainURL, statusCode: 200, HTTPVersion: nil, headerFields: nil)

                it("should yield success with payload") {
                    let response = Response(data: data, response: http, error: nil)
                    var actual: Result<Management.Object, Management.Error>? = nil
                    management.managementObject(response) { actual = $0 }
                    expect(actual).toEventually(haveObjectWithAttributes(["key"]))
                }
            }

            context("failure") {

                it("should yield invalid json response") {
                    let data = "NOT JSON".dataUsingEncoding(NSUTF8StringEncoding)!
                    let http = NSHTTPURLResponse(URL: DomainURL, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                    let response = Response(data: data, response: http, error: nil)
                    var actual: Result<Management.Object, Management.Error>? = nil
                    management.managementObject(response) { actual = $0 }
                    expect(actual).toEventually(beInvalidResponse())
                }

                it("should yield invalid response") {
                    let data = "[{\"key\": \"value\"}]".dataUsingEncoding(NSUTF8StringEncoding)!
                    let http = NSHTTPURLResponse(URL: DomainURL, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                    let response = Response(data: data, response: http, error: nil)
                    var actual: Result<Management.Object, Management.Error>? = nil
                    management.managementObject(response) { actual = $0 }
                    expect(actual).toEventually(beInvalidResponse())
                }

                it("should yield generic failure when error response is unknown") {
                    let data = "[{\"key\": \"value\"}]".dataUsingEncoding(NSUTF8StringEncoding)!
                    let http = NSHTTPURLResponse(URL: DomainURL, statusCode: 400, HTTPVersion: nil, headerFields: nil)
                    let response = Response(data: data, response: http, error: nil)
                    var actual: Result<Management.Object, Management.Error>? = nil
                    management.managementObject(response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

                it("should yield server error") {
                    let error = ["error": "error", "description": "description", "code": "code"]
                    let data = try? NSJSONSerialization.dataWithJSONObject(error, options: [])
                    let http = NSHTTPURLResponse(URL: DomainURL, statusCode: 400, HTTPVersion: nil, headerFields: nil)
                    let response = Response(data: data, response: http, error: nil)
                    var actual: Result<Management.Object, Management.Error>? = nil
                    management.managementObject(response) { actual = $0 }
                    expect(actual).toEventually(haveError("error", description: "description", code: "code", statusCode: 400))
                }

                it("should yield generic failure when no payload") {
                    let http = NSHTTPURLResponse(URL: DomainURL, statusCode: 400, HTTPVersion: nil, headerFields: nil)
                    let response = Response(data: nil, response: http, error: nil)
                    var actual: Result<Management.Object, Management.Error>? = nil
                    management.managementObject(response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

                it("should yield generic failure") {
                    let response = Response(data: nil, response: nil, error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
                    var actual: Result<Management.Object, Management.Error>? = nil
                    management.managementObject(response) { actual = $0 }
                    expect(actual).toEventually(beFailure())
                }

            }
        }
    }
}
