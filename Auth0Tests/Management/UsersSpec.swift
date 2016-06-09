// UsersSpec.swift
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

@testable import Auth0

private let Domain = "samples.auth0.com"
private let Token = NSUUID().UUIDString
private let NonExistentUser = "auth0|notfound"
private let Timeout: NSTimeInterval = 2

class UsersSpec: QuickSpec {

    override func spec() {

        let users = Auth0.users(token: Token, domain: Domain)

        afterEach {
            OHHTTPStubs.removeAllStubs()
            stub(isHost(Domain)) { _ in OHHTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }
                .name = "YOU SHALL NOT PASS!"
        }

        describe("GET /users/:identifier") {

            beforeEach {
                stub(isUsersPath(Domain, identifier: UserId) && isMethodGET())
                { _ in managementResponse(["user_id": UserId, "email": SupportAtAuth0]) }
                .name = "User Fetch"

                stub(isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasQueryParameters(["fields": "user_id", "include_fields": "true"]))
                { _ in managementResponse(["user_id": UserId]) }
                .name = "User Fetch including fields"

                stub(isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasQueryParameters(["fields": "user_id", "include_fields": "false"]))
                { _ in managementResponse(["email": SupportAtAuth0]) }
                    .name = "User Fetch excluding fields"
            }

            it("should return single user by id") {
                waitUntil(timeout: Timeout) { done in
                    users.get(UserId).start { result in
                        expect(result).to(haveObjectWithAttributes(["user_id", "email"]))
                        done()
                    }
                }
            }

            it("should return specified user fields") {
                waitUntil(timeout: Timeout) { done in
                    users.get(UserId, fields: ["user_id"]).start { result in
                        expect(result).to(haveObjectWithAttributes(["user_id"]))
                        done()
                    }
                }
            }

            it("should exclude specified user fields") {
                waitUntil(timeout: Timeout) { done in
                    users.get(UserId, fields: ["user_id"], include: false).start { result in
                        expect(result).to(haveObjectWithAttributes(["email"]))
                        done()
                    }
                }
            }

            it("should fail request") {
                stub(isUsersPath(Domain, identifier: NonExistentUser) && isMethodGET()) { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}
                waitUntil(timeout: Timeout) { done in
                    users.get(NonExistentUser).start { result in
                        expect(result).to(haveError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }
        }

        describe("PATCH /users/:identifier") {

            it("should send attributes") {
                stub(isUsersPath(Domain, identifier: UserId) && isMethodPATCH() && hasAllOf(["username": Support, "connection": "facebook"]))
                { _ in managementResponse(["user_id": UserId, "email": SupportAtAuth0, "username": Support, "connection": "facebook"]) }
                .name = "User Patch"

                waitUntil(timeout: Timeout) { done in
                    let attributes = UserPatchAttributes().username(Support, connection: "facebook")
                    users.patch(UserId, attributes: attributes).start { result in
                        expect(result).to(haveObjectWithAttributes(["user_id", "email", "username", "connection"]))
                        done()
                    }
                }
            }

            it("should patch userMetadata") {
                let metadata = ["role": "admin"]
                stub(isUsersPath(Domain, identifier: UserId) && isMethodPATCH() && hasUserMetadata(metadata))
                { _ in managementResponse(["user_id": UserId, "email": SupportAtAuth0]) }
                    .name = "User Patch user_metadata"

                waitUntil(timeout: Timeout) { done in
                    users.patch(UserId, userMetadata: metadata).start { result in
                        expect(result).to(haveObjectWithAttributes(["user_id", "email"]))
                        done()
                    }
                }
            }

            it("should fail request") {
                stub(isUsersPath(Domain, identifier: NonExistentUser) && isMethodPATCH()) { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}
                waitUntil(timeout: Timeout) { done in
                    users.patch(NonExistentUser, attributes: UserPatchAttributes().blocked(true)).start { result in
                        expect(result).to(haveError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

        }

        describe("PATCH /users/:identifier/identities") {

            it("shoud link with just a token") {
                stub(isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["link_with": "token"]))
                { _ in managementResponse([["user_id": UserId, "email": SupportAtAuth0]])}
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withOtherUserToken: "token").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("shoud link without a token") {
                stub(isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["user_id": "other_id", "provider": "facebook"]))
                { _ in managementResponse([["user_id": UserId, "email": SupportAtAuth0]])}
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: "facebook").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("shoud link without a token specifying a connection id") {
                stub(isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["user_id": "other_id", "provider": "facebook", "connection_id": "conn_1"]))
                { _ in managementResponse([["user_id": UserId, "email": SupportAtAuth0]])}
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: "facebook", connectionId: "conn_1").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail request") {
                stub(isLinkPath(Domain, identifier: NonExistentUser) && isMethodPOST())
                { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}
                waitUntil(timeout: Timeout) { done in
                    users.link(NonExistentUser, withOtherUserToken: "token").start { result in
                        expect(result).to(haveError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

        }
    }

}