// UsersSpec.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
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
import OHHTTPStubs
import Auth0

let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhdXRoMDEyMzQ1Njc4OTAifQ.THyUGyQ5rPMcGSb7UyQU-O783DhGZZrUH_XesYxqbKc"
let userId = "auth01234567890"
let error = NSError(domain: "com.auth0", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed Mocked Request"])

class UsersSpec: QuickSpec {
    override func spec() {

        let users = API(domain: "https://samples.auth0.com").users(jwt)
        var request: FilteredRequest = none()

        afterEach() {
            OHHTTPStubs.removeAllStubs()
            all().stubWithName("THOU SHALL NOT PASS!", error: NSError(domain: "com.auth0", code: -1, userInfo: nil))
        }

        describe("updateUserMetadata") {

            beforeEach {
                request = filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "PATCH" }
            }

            context("successful request") {
                beforeEach {
                    request.stubWithName("PATCH user_metadata", json: ["user_id": userId])
                }

                it("should not yield error") {
                    waitUntil { done in
                        users.updateMetadata(["key": "value"]).responseJSON { error, payload in
                            done()
                            expect(error).to(beNil())
                        }
                    }
                }

                it("should yield JSON payload") {
                    waitUntil { done in
                        users.updateMetadata(["key": "value"]).responseJSON { error, payload in
                            done()
                            expect(payload).toNot(beNil())
                            expect(payload?["user_id"] as? String).to(equal(userId))
                        }
                    }
                }
            }

            context("failed request no response") {
                beforeEach {
                    request.stubWithName("PATCH user_metadata error", error: error)
                }

                it("should not yield payload") {
                    waitUntil { done in
                        users.updateMetadata(["key": "value"]).responseJSON { error, payload in
                            done()
                            expect(payload).to(beNil())
                        }
                    }
                }

                it("should yield error") {
                    waitUntil { done in
                        users.updateMetadata(["key": "value"]).responseJSON { err, payload in
                            done()
                            expect(err).to(equal(error))
                        }
                    }
                }
            }

            context("failed request with error payload") {
                let invalidRequestJson = ["error_code": "invalid_request"]

                beforeEach {
                    request.stubWithName("PATCH user_metadata bad request", json: invalidRequestJson, statusCode: 400)
                }

                it("should not yield payload") {
                    waitUntil { done in
                        users.updateMetadata(["key": "value"]).responseJSON { error, payload in
                            done()
                            expect(payload).to(beNil())
                        }
                    }
                }

                it("should yield error with response") {
                    waitUntil { done in
                        users.updateMetadata(["key": "value"]).responseJSON { error, payload in
                            done()
                            expect(error).toNot(beNil())
                            expect(error?.userInfo?[APIRequestErrorStatusCodeKey as NSObject] as? Int).to(equal(400))
                            expect(error?.userInfo?[APIRequestErrorErrorKey as NSObject] as? [String: String]).to(equal(invalidRequestJson))
                        }
                    }
                }

            }
        }
    }
}
