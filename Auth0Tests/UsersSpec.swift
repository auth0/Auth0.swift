import Foundation
import Quick
import Nimble
@testable import Auth0

private let Domain = "samples.auth0.com"
private let Token = UUID().uuidString
private let NonExistentUser = "auth0|notfound"
private let Timeout: NimbleTimeInterval = .seconds(2)
private let Provider = "facebook"

class UsersSpec: QuickSpec {

    override class func spec() {

        let users = Auth0.users(token: Token, domain: Domain)

        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        describe("GET /users/:identifier") {

            beforeEach {
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: UserId) && $0.isMethodGET && $0.hasBearerToken(Token) && $0.hasQueryParameters(["fields": "user_id", "include_fields": "true"])}, response:apiSuccessResponse(json: ["user_id": UserId]))
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: UserId) && $0.isMethodGET && $0.hasBearerToken(Token) && $0.hasQueryParameters(["fields": "user_id", "include_fields": "false"])}, response:apiSuccessResponse(json: ["email": SupportAtAuth0]))
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: UserId) && $0.isMethodGET && $0.hasBearerToken(Token) }, response:apiSuccessResponse(json: ["user_id": UserId, "email": SupportAtAuth0]))
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

            it("should fail request with management error") {
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: NonExistentUser) && $0.isMethodGET && $0.hasBearerToken(Token) }, response:managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.get(NonExistentUser).start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: NonExistentUser) && $0.isMethodGET && $0.hasBearerToken(Token) }, response:apiFailureResponse(string: "foo", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.get(NonExistentUser).start { result in
                        expect(result).to(haveManagementError(description: "foo", statusCode: 400))
                        done()
                    }
                }
            }

        }

        describe("PATCH /users/:identifier") {

            it("should send attributes") {
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: UserId) && $0.isMethodPATCH && $0.hasAllOf(["username": Support, "connection": Provider]) && $0.hasBearerToken(Token) }, response:apiSuccessResponse(json: ["user_id": UserId, "email": SupportAtAuth0, "username": Support, "connection": Provider]))

                waitUntil(timeout: Timeout) { done in
                    let attributes = UserPatchAttributes().username(Support, connection: Provider)
                    users.patch(UserId, attributes: attributes).start { result in
                        expect(result).to(haveObjectWithAttributes(["user_id", "email", "username", "connection"]))
                        done()
                    }
                }
            }

            it("should patch userMetadata") {
                let metadata = ["role": "admin"]
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: UserId) && $0.isMethodPATCH && $0.hasUserMetadata(metadata) && $0.hasBearerToken(Token) }, response:apiSuccessResponse(json: ["user_id": UserId, "email": SupportAtAuth0]))

                waitUntil(timeout: Timeout) { done in
                    users.patch(UserId, userMetadata: metadata).start { result in
                        expect(result).to(haveObjectWithAttributes(["user_id", "email"]))
                        done()
                    }
                }
            }

            it("should fail request with management error") {
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: NonExistentUser) && $0.isMethodPATCH && $0.hasBearerToken(Token) }, response:managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.patch(NonExistentUser, attributes: UserPatchAttributes().blocked(true)).start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                NetworkStub.addStub(condition: {
                    $0.isUsersPath(Domain, identifier: NonExistentUser) && $0.isMethodPATCH && $0.hasBearerToken(Token) }, response: apiFailureResponse(string: "foo", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.patch(NonExistentUser, attributes: UserPatchAttributes().blocked(true)).start { result in
                        expect(result).to(haveManagementError(description: "foo", statusCode: 400))
                        done()
                    }
                }
            }

        }

        describe("PATCH /users/:identifier/identities") {

            it("should link with just a token") {
                
                NetworkStub.addStub(condition: {
                    $0.isLinkPath(Domain, identifier: UserId) && $0.isMethodPOST && $0.hasAllOf(["link_with": "token"]) && $0.hasBearerToken(Token) }
                                    , response: apiSuccessResponse(jsonArray: [["user_id": UserId, "email": SupportAtAuth0]]))
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withOtherUserToken: "token").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should link without a token") {
                NetworkStub.addStub(condition: {
                    $0.isLinkPath(Domain, identifier: UserId) && $0.isMethodPOST && $0.hasAllOf(["user_id": "other_id", "provider": Provider]) && $0.hasBearerToken(Token) }
                                    , response: apiSuccessResponse(jsonArray: [["user_id": UserId, "email": SupportAtAuth0]]))
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: Provider).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should link without a token specifying a connection id") {
                NetworkStub.addStub(condition: {
                    $0.isLinkPath(Domain, identifier: UserId) && $0.isMethodPOST && $0.hasAllOf(["user_id": "other_id", "provider": Provider, "connection_id": "conn_1"]) && $0.hasBearerToken(Token) }
                                    , response: apiSuccessResponse(jsonArray: [["user_id": UserId, "email": SupportAtAuth0]]))
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: Provider, connectionId: "conn_1").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail request with management error") {
                NetworkStub.addStub(condition: {
                    $0.isLinkPath(Domain, identifier: NonExistentUser) && $0.isMethodPOST && $0.hasBearerToken(Token) }
                                    ,response: managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.link(NonExistentUser, withOtherUserToken: "token").start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                NetworkStub.addStub(condition: {
                    $0.isLinkPath(Domain, identifier: NonExistentUser) && $0.isMethodPOST && $0.hasBearerToken(Token) }
                                    ,response: apiFailureResponse(string: "foo", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.link(NonExistentUser, withOtherUserToken: "token").start { result in
                        expect(result).to(haveManagementError(description: "foo", statusCode: 400))
                        done()
                    }
                }
            }

        }

        describe("DELETE /users/:identifier/identities/:provider/:identityId") {

            it("should unlink") {
                NetworkStub.addStub(condition: {
                    $0.isUnlinkPath(Domain, identifier: "other_id", provider: Provider, identityId: UserId) && $0.isMethodDELETE && $0.hasBearerToken(Token)
                }, response: apiSuccessResponse(jsonArray: []))
                waitUntil(timeout: Timeout) { done in
                    users.unlink(identityId: UserId, provider: Provider, fromUserId: "other_id").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail request with management error") {
                NetworkStub.addStub(condition: {
                    $0.isUnlinkPath(Domain, identifier: "other_id", provider: Provider, identityId: NonExistentUser) && $0.isMethodDELETE && $0.hasBearerToken(Token)
                }, response: managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.unlink(identityId: NonExistentUser, provider: Provider, fromUserId: "other_id").start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                NetworkStub.addStub(condition: {
                    $0.isUnlinkPath(Domain, identifier: "other_id", provider: Provider, identityId: NonExistentUser) && $0.isMethodDELETE && $0.hasBearerToken(Token)
                }, response: apiFailureResponse(string: "foo", statusCode: 400))
                waitUntil(timeout: Timeout) { done in
                    users.unlink(identityId: NonExistentUser, provider: Provider, fromUserId: "other_id").start { result in
                        expect(result).to(haveManagementError(description: "foo", statusCode: 400))
                        done()
                    }
                }
            }

        }

    }

}
