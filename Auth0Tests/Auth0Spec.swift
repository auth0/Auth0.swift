// Auth0Spec.swift
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
import OHHTTPStubs
import Alamofire

@testable import Auth0

let ClientId = "CLIENT_ID"
let Domain = "samples.auth0.com"

let Timeout: NSTimeInterval = 1000000


let SupportAtAuth0 = "support@auth0.com"
let ValidPassword = "I.O.U. a password"
let ConnectionName = "Username-Password-Authentication"
let AccessToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
let IdToken = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")

class Auth0Spec: QuickSpec {
    override func spec() {

        afterEach {
            OHHTTPStubs.removeAllStubs()
            stub(isHost(Domain)) { _ in
                return OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
            }
        }

        describe("endpoints") {

            it("should return authentication endpoint with clientId and domain") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                expect(auth).toNot(beNil())
                expect(auth.clientId) ==  ClientId
                expect(auth.url.absoluteString) == "https://\(Domain)"
            }


            it("should return authentication endpoint with domain url") {
                let domain = "https://mycustomdomain.com"
                let auth = Auth0.authentication(clientId: ClientId, domain: domain)
                expect(auth.url.absoluteString).to(equal(domain))
            }

        }

        describe("authentication") {

            let auth = Authentication(clientId: ClientId, url: NSURL(string: "https://\(Domain)")!, manager: TestManager())

            beforeEach {
                stub(isHost(Domain) && isPath("/oauth/ro") && hasParameters(["username":SupportAtAuth0, "password": ValidPassword, "scope": "openid"])) { request in
                    return OHHTTPStubsResponse(JSONObject: ["access_token": AccessToken, "id_token": IdToken], statusCode: 200, headers: nil)
                }
                stub(isHost(Domain) && isPath("/oauth/ro") && hasParameters(["username":SupportAtAuth0, "password": ValidPassword]) && hasNoneOf(["scope": "openid"])) { request in
                    return OHHTTPStubsResponse(JSONObject: ["access_token": AccessToken], statusCode: 200, headers: nil)
                }
            }

            context("login") {

                it("should login with username and password") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName) { result in
                            expect(result).to(hasCredentials())
                            done()
                        }
                    }
                }

                it("should have an access_token") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "read:users") { result in
                            expect(result).to(hasCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should have both token when scope is 'openid'") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(SupportAtAuth0, password: ValidPassword, connection: ConnectionName, scope: "openid") { result in
                            expect(result).to(hasCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }

                it("should report when fails to login") {
                    waitUntil(timeout: Timeout) { done in
                        auth.login(SupportAtAuth0, password: "invalid", connection: ConnectionName) { result in
                            expect(result).toNot(hasCredentials())
                            done()
                        }
                    }
                }

            }
        }
    }
}