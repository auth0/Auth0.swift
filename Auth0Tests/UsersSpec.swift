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

let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiI4OVFJZTAzZk0xMjM0NTY3OFFhWGh6bkZialRhUWJVNSIsInNjb3BlcyI6eyJ1c2VycyI6eyJhY3Rpb25zIjpbInVwZGF0ZSJdfX0sImlhdCI6MTQzNTcwNjI1MSwianRpIjoiZDFlZGNiMDkwMmRjNDNhYjgzYTYyNDNmMTcyZjY1ZjgifQ.Hyazrf5iYZM_-5qVrrs60HkSTxk3BoYWwP1bGmqQLfs"
let id_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhdXRoMDEyMzQ1Njc4OTAifQ.THyUGyQ5rPMcGSb7UyQU-O783DhGZZrUH_XesYxqbKc"
let userId = "auth01234567890"
let error = NSError(domain: "com.auth0.api", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed Mocked Request"])

let patch_user_ok = "successful PATCH user"
let patch_user_error = "failed PATCH user"
let get_user_ok = "successful GET user"
let get_user_error = "failed GET user"

class UpdateMetadataSharedExamplesConfiguration: QuickConfiguration {
    override class func configure(configuration: Configuration) {
        sharedExamples(patch_user_ok) { (sharedExampleContext: SharedExampleContext) in
            let users = sharedExampleContext()["users"] as! Users
            let id = sharedExampleContext()["id"] as? String
            let userMetadata = sharedExampleContext()["user_metadata"] as? [String: AnyObject]
            let appMetadata = sharedExampleContext()["app_metadata"] as? [String: AnyObject]
            let parameters = sharedExampleContext()["parameters"] as? [String: AnyObject]

            it("should not yield error") {
                waitUntil { done in
                    users.update(id: id, userMetadata: userMetadata, appMetadata: appMetadata, parameters: parameters).responseJSON { error, payload in
                        expect(error).to(beNil())
                        done()
                    }
                }
            }

            it("should yield JSON payload") {
                waitUntil { done in
                    users.update(id: id, userMetadata: userMetadata, appMetadata: appMetadata, parameters: parameters).responseJSON { error, payload in
                        expect(payload).toNot(beNil())
                        expect(payload?["user_id"] as? String).toNot(beNil())
                        done()
                    }
                }
            }
        }

        sharedExamples(patch_user_error) { (sharedExampleContext: SharedExampleContext) in
            let users = sharedExampleContext()["users"] as! Users
            let id = sharedExampleContext()["id"] as? String
            let userMetadata = sharedExampleContext()["user_metadata"] as? [String: AnyObject]
            let appMetadata = sharedExampleContext()["app_metadata"] as? [String: AnyObject]
            let parameters = sharedExampleContext()["parameters"] as? [String: AnyObject]

            it("should not yield payload") {
                waitUntil { done in
                    users.update(id: id, userMetadata: userMetadata, appMetadata: appMetadata, parameters: parameters).responseJSON { error, payload in
                        expect(payload).to(beNil())
                        done()
                    }
                }
            }

            it("should yield error") {
                waitUntil { done in
                    users.update(id: id, userMetadata: userMetadata, appMetadata: appMetadata, parameters: parameters).responseJSON { err, payload in
                        expect(err).toNot(beNil())
                        expect(err?.domain).to(equal("com.auth0.api"))
                        done()
                    }
                }
            }
        }

        sharedExamples(get_user_ok) { (sharedExampleContext: SharedExampleContext) in
            let users = sharedExampleContext()["users"] as! Users
            let id = sharedExampleContext()["id"] as? String

            it("should yield user") {
                waitUntil { done in
                    users.find(id: id).responseJSON { error, payload in
                        expect(payload).toNot(beNil())
                        expect(payload?["user_id"] as? String).to(equal(id))
                        done()
                    }
                }
            }

            it("should not yield error") {
                waitUntil { done in
                    users.find(id: id).responseJSON { error, payload in
                        expect(error).to(beNil())
                        done()
                    }
                }
            }
        }

        sharedExamples(get_user_error) { (sharedExampleContext: SharedExampleContext) in
            let users = sharedExampleContext()["users"] as! Users
            let id = sharedExampleContext()["id"] as? String

            it("should not yield payload") {
                waitUntil { done in
                    users.find(id: id).responseJSON { error, payload in
                        expect(payload).to(beNil())
                        done()
                    }
                }
            }

            it("should yield error") {
                waitUntil { done in
                    users.find(id: id).responseJSON { err, payload in
                        expect(err).toNot(beNil())
                        expect(err?.domain).to(equal("com.auth0.api"))
                        done()
                    }
                }
            }
        }

    }
}

class UsersSpec: QuickSpec {
    override func spec() {

        let api = API(domain: "https://samples.auth0.com")
        var request: FilteredRequest = none()

        beforeEach {
            all().stubWithName("THOU SHALL NOT PASS!", error: NSError(domain: "com.auth0", code: -1, userInfo: nil))
        }

        afterEach {
            OHHTTPStubs.removeAllStubs()
        }

        it("should send all parameters") {
            let parameters = [
                "email": "mail@mail.com",
                "blocked": false,
                "verify_email": true,
            ]
            let userMetadata = ["first_name": "John"]
            let appMetadata = ["role": "admin"]

            var all: [String: AnyObject] = parameters
            all["user_metadata"] = userMetadata
            all["app_metadata"] = appMetadata

            filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "PATCH" && hasJSON(all, $0) }.stubWithName("PATCH user", json: ["user_id": userId])

            waitUntil { done in
                api
                    .users(id_token)
                    .update(userMetadata: userMetadata, appMetadata: appMetadata, parameters: parameters)
                    .responseJSON { err, payload in
                        expect(payload).toNot(beNil())
                        expect(payload?["user_id"] as? String).toNot(beNil())
                        done()
                }
            }
        }

        describe("update user_metadata with id_token") {

            let users = api.users(id_token)

            beforeEach {
                request = filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "PATCH" }
            }

            context("successful request") {
                beforeEach {
                    request.stubWithName("PATCH user_metadata", json: ["user_id": userId])
                }

                itBehavesLike(patch_user_ok) { ["users": users, "user_metadata": ["key": "value"]] }

            }

            context("failed request no response") {
                beforeEach {
                    request.stubWithName("PATCH user_metadata error", error: error)
                }

                itBehavesLike(patch_user_error) { ["users": users, "user_metadata": ["key": "value"]] }
            }

            context("failed request with error payload") {
                let invalidRequestJson = ["error_code": "invalid_request"]

                beforeEach {
                    request.stubWithName("PATCH user_metadata bad request", json: invalidRequestJson, statusCode: 400)
                }

                it("should yield error with response") {
                    waitUntil { done in
                        users.update(userMetadata: ["key": "value"]).responseJSON { error, payload in
                            expect(error).toNot(beNil())
                            expect(error?.userInfo?[APIRequestErrorStatusCodeKey as NSObject] as? Int).to(equal(400))
                            expect(error?.userInfo?[APIRequestErrorErrorKey as NSObject] as? [String: String]).to(equal(invalidRequestJson))
                            done()
                        }
                    }
                }
            }
        }

        describe("update user_metadata with jwt") {

            let users = api.users(jwt)

            beforeEach {
                request = filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "PATCH" }
            }

            context("successful request") {
                beforeEach {
                    request.stubWithName("PATCH user_metadata", json: ["user_id": userId])
                }

                itBehavesLike(patch_user_ok) { ["users": users, "user_metadata": ["key": "value"], "id": userId] }

            }

            context("failed request no response") {
                beforeEach {
                    request.stubWithName("PATCH user_metadata error", error: error)
                }

                itBehavesLike(patch_user_error) { ["users": users, "user_metadata": ["key": "value"], "id": userId] }
            }

            context("failed request with error payload") {
                let invalidRequestJson = ["error_code": "invalid_request"]

                beforeEach {
                    request.stubWithName("PATCH user_metadata bad request", json: invalidRequestJson, statusCode: 400)
                }

                itBehavesLike(patch_user_error) { ["users": users, "user_metadata": ["key": "value"], "id": userId] }

                it("should yield error with response") {
                    waitUntil { done in
                        users.update(id: userId, userMetadata: ["key": "value"]).responseJSON { error, payload in
                            expect(error).toNot(beNil())
                            expect(error?.userInfo?[APIRequestErrorStatusCodeKey as NSObject] as? Int).to(equal(400))
                            expect(error?.userInfo?[APIRequestErrorErrorKey as NSObject] as? [String: String]).to(equal(invalidRequestJson))
                            done()
                        }
                    }
                }
            }

            context("failed request when no id is provided") {

                itBehavesLike(patch_user_error) { ["users": users, "user_metadata": ["key": "value"]] }

                it("should yield error with response") {
                    waitUntil { done in
                        users.update(userMetadata: ["key": "value"]).responseJSON { error, payload in
                            expect(error).toNot(beNil())
                            expect(error?.userInfo?[NSLocalizedDescriptionKey] as? String).to(equal("No id of a user supplied to perform the update"))
                            done()
                        }
                    }
                }

            }

            describe("update app_metadata with id_token") {

                let users = api.users(id_token)

                beforeEach {
                    request = filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "PATCH" }
                }

                context("successful request") {
                    beforeEach {
                        request.stubWithName("PATCH app_metadata", json: ["user_id": userId])
                    }

                    itBehavesLike(patch_user_ok) { ["users": users, "app_metadata": ["key": "value"]] }

                }

                context("failed request no response") {
                    beforeEach {
                        request.stubWithName("PATCH app_metadata error", error: error)
                    }

                    itBehavesLike(patch_user_error) { ["users": users, "app_metadata": ["key": "value"]] }
                }

                context("failed request with error payload") {
                    let invalidRequestJson = ["error_code": "invalid_request"]

                    beforeEach {
                        request.stubWithName("PATCH app_metadata bad request", json: invalidRequestJson, statusCode: 400)
                    }

                    it("should yield error with response") {
                        waitUntil { done in
                            users.update(userMetadata: ["key": "value"]).responseJSON { error, payload in
                                expect(error).toNot(beNil())
                                expect(error?.userInfo?[APIRequestErrorStatusCodeKey as NSObject] as? Int).to(equal(400))
                                expect(error?.userInfo?[APIRequestErrorErrorKey as NSObject] as? [String: String]).to(equal(invalidRequestJson))
                                done()
                            }
                        }
                    }
                }
            }

            describe("update app_metadata with jwt") {

                let users = api.users(jwt)

                beforeEach {
                    request = filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "PATCH" }
                }

                context("successful request") {
                    beforeEach {
                        request.stubWithName("PATCH app_metadata", json: ["user_id": userId])
                    }

                    itBehavesLike(patch_user_ok) { ["users": users, "app_metadata": ["key": "value"], "id": userId] }

                }

                context("failed request no response") {
                    beforeEach {
                        request.stubWithName("PATCH app_metadata error", error: error)
                    }

                    itBehavesLike(patch_user_error) { ["users": users, "app_metadata": ["key": "value"], "id": userId] }
                }

                context("failed request with error payload") {
                    let invalidRequestJson = ["error_code": "invalid_request"]

                    beforeEach {
                        request.stubWithName("PATCH app_metadata bad request", json: invalidRequestJson, statusCode: 400)
                    }

                    itBehavesLike(patch_user_error) { ["users": users, "app_metadata": ["key": "value"], "id": userId] }

                    it("should yield error with response") {
                        waitUntil { done in
                            users.update(id: userId, userMetadata: ["key": "value"]).responseJSON { error, payload in
                                expect(error).toNot(beNil())
                                expect(error?.userInfo?[APIRequestErrorStatusCodeKey as NSObject] as? Int).to(equal(400))
                                expect(error?.userInfo?[APIRequestErrorErrorKey as NSObject] as? [String: String]).to(equal(invalidRequestJson))
                                done()
                            }
                        }
                    }
                }
            }

            describe("get user with id_token") {

                let users = api.users(id_token)

                beforeEach {
                    request = filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "GET" }
                }

                context("successful request") {
                    beforeEach {
                        request.stubWithName("GET app_metadata", json: ["user_id": userId])
                    }

                    itBehavesLike(get_user_ok) { ["users": users, "id": userId] }
                }

                context("failed request no response") {
                    beforeEach {
                        request.stubWithName("GET app_metadata error", error: error)
                    }

                    itBehavesLike(get_user_error) { ["users": users] }
                }

                context("failed request with error payload") {
                    let invalidRequestJson = ["error_code": "invalid_request"]

                    beforeEach {
                        request.stubWithName("GET app_metadata bad request", json: invalidRequestJson, statusCode: 400)
                    }

                    itBehavesLike(get_user_error) { ["users": users] }

                    it("should yield error with response") {
                        waitUntil { done in
                            users.find().responseJSON { error, payload in
                                expect(error).toNot(beNil())
                                expect(error?.userInfo?[APIRequestErrorStatusCodeKey as NSObject] as? Int).to(equal(400))
                                expect(error?.userInfo?[APIRequestErrorErrorKey as NSObject] as? [String: String]).to(equal(invalidRequestJson))
                                done()
                            }
                        }
                    }
                }
            }

            describe("get user with jwt") {

                let users = api.users(jwt)

                beforeEach {
                    request = filter { return $0.URL!.path == "/api/v2/users/\(userId)" && $0.HTTPMethod == "GET" }
                }

                context("successful request") {
                    beforeEach {
                        request.stubWithName("GET app_metadata", json: ["user_id": userId])
                    }

                    itBehavesLike(get_user_ok) { ["users": users, "id": userId] }
                    itBehavesLike(get_user_ok) { ["users": users, "id": userId] }
                }

                context("failed request no response") {
                    beforeEach {
                        request.stubWithName("GET app_metadata error", error: error)
                    }

                    itBehavesLike(get_user_error) { ["users": users, "id": userId] }
                    itBehavesLike(get_user_error) { ["users": users, "id": userId] }
                }

                context("failed request with error payload") {
                    let invalidRequestJson = ["error_code": "invalid_request"]

                    beforeEach {
                        request.stubWithName("GET app_metadata bad request", json: invalidRequestJson, statusCode: 400)
                    }

                    itBehavesLike(get_user_error) { ["users": users, "id": userId] }
                    itBehavesLike(get_user_error) { ["users": users, "id": userId] }

                    it("should yield error with response") {
                        waitUntil { done in
                            users.find(id: userId).responseJSON { error, payload in
                                expect(error).toNot(beNil())
                                expect(error?.userInfo?[APIRequestErrorStatusCodeKey as NSObject] as? Int).to(equal(400))
                                expect(error?.userInfo?[APIRequestErrorErrorKey as NSObject] as? [String: String]).to(equal(invalidRequestJson))
                                done()
                            }
                        }
                    }
                }
                
            }

        }
    }
}
