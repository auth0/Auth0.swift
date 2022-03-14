import Foundation
import Quick
import Nimble
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

private let Domain = "samples.auth0.com"
private let Token = UUID().uuidString
private let NonExistentUser = "auth0|notfound"
private let Timeout: DispatchTimeInterval = .seconds(2)
private let Provider = "facebook"

class UsersSpec: QuickSpec {

    override func spec() {

        let users = Auth0.users(token: Token, domain: Domain)

        beforeEach {
            stub(condition: isHost(Domain)) { _ in catchAllResponse() }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("GET /users/:identifier") {

            beforeEach {
                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasBearerToken(Token))
                { _ in apiSuccessResponse(json: ["user_id": UserId, "email": SupportAtAuth0]) }
                .name = "User Fetch"

                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasQueryParameters(["fields": "user_id", "include_fields": "true"]) && hasBearerToken(Token))
                { _ in apiSuccessResponse(json: ["user_id": UserId]) }
                .name = "User Fetch including fields"

                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasQueryParameters(["fields": "user_id", "include_fields": "false"]) && hasBearerToken(Token))
                { _ in apiSuccessResponse(json: ["email": SupportAtAuth0]) }
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

            it("should fail request with management error") {
                stub(condition: isUsersPath(Domain, identifier: NonExistentUser) && isMethodGET() && hasBearerToken(Token)) { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}.name = "user not found"
                waitUntil(timeout: Timeout) { done in
                    users.get(NonExistentUser).start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                stub(condition: isUsersPath(Domain, identifier: NonExistentUser) && isMethodGET() && hasBearerToken(Token)) { _ in
                    return apiFailureResponse(string: "foo", statusCode: 400)
                }.name = "user not found"
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
                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodPATCH() && hasAllOf(["username": Support, "connection": Provider]) && hasBearerToken(Token))
                { _ in apiSuccessResponse(json: ["user_id": UserId, "email": SupportAtAuth0, "username": Support, "connection": Provider]) }
                .name = "User Patch"

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
                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodPATCH() && hasUserMetadata(metadata) && hasBearerToken(Token))
                { _ in apiSuccessResponse(json: ["user_id": UserId, "email": SupportAtAuth0]) }
                    .name = "User Patch user_metadata"

                waitUntil(timeout: Timeout) { done in
                    users.patch(UserId, userMetadata: metadata).start { result in
                        expect(result).to(haveObjectWithAttributes(["user_id", "email"]))
                        done()
                    }
                }
            }

            it("should fail request with management error") {
                stub(condition: isUsersPath(Domain, identifier: NonExistentUser) && isMethodPATCH() && hasBearerToken(Token)) { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}.name = "user not found"
                waitUntil(timeout: Timeout) { done in
                    users.patch(NonExistentUser, attributes: UserPatchAttributes().blocked(true)).start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                stub(condition: isUsersPath(Domain, identifier: NonExistentUser) && isMethodPATCH() && hasBearerToken(Token)) { _ in
                    return apiFailureResponse(string: "foo", statusCode: 400)
                }.name = "user not found"
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
                stub(condition: isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["link_with": "token"]) && hasBearerToken(Token))
                { _ in apiSuccessResponse(jsonArray: [["user_id": UserId, "email": SupportAtAuth0]])}.name = "user linked"
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withOtherUserToken: "token").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should link without a token") {
                stub(condition: isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["user_id": "other_id", "provider": Provider]) && hasBearerToken(Token))
                { _ in apiSuccessResponse(jsonArray: [["user_id": UserId, "email": SupportAtAuth0]])}.name = "user linked"
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: Provider).start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should link without a token specifying a connection id") {
                stub(condition: isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["user_id": "other_id", "provider": Provider, "connection_id": "conn_1"]) && hasBearerToken(Token))
                { _ in apiSuccessResponse(jsonArray: [["user_id": UserId, "email": SupportAtAuth0]])}.name = "user linked"
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: Provider, connectionId: "conn_1").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail request with management error") {
                stub(condition: isLinkPath(Domain, identifier: NonExistentUser) && isMethodPOST() && hasBearerToken(Token))
                { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}.name = "user not found"
                waitUntil(timeout: Timeout) { done in
                    users.link(NonExistentUser, withOtherUserToken: "token").start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                stub(condition: isLinkPath(Domain, identifier: NonExistentUser) && isMethodPOST() && hasBearerToken(Token)) { _ in
                    return apiFailureResponse(string: "foo", statusCode: 400)
                }.name = "user not found"
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
                stub(condition: isUnlinkPath(Domain, identifier: "other_id", provider: Provider, identityId: UserId) && isMethodDELETE() && hasBearerToken(Token)) { _ in
                    return apiSuccessResponse(jsonArray: [])
                }.name = "user unlinked"
                waitUntil(timeout: Timeout) { done in
                    users.unlink(identityId: UserId, provider: Provider, fromUserId: "other_id").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail request with management error") {
                stub(condition: isUnlinkPath(Domain, identifier: "other_id", provider: Provider, identityId: NonExistentUser) && isMethodDELETE() && hasBearerToken(Token)) { _ in
                    return managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)
                }.name = "user not found"
                waitUntil(timeout: Timeout) { done in
                    users.unlink(identityId: NonExistentUser, provider: Provider, fromUserId: "other_id").start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

            it("should fail request with generic error") {
                stub(condition: isUnlinkPath(Domain, identifier: "other_id", provider: Provider, identityId: NonExistentUser) && isMethodDELETE() && hasBearerToken(Token)) { _ in
                    return apiFailureResponse(string: "foo", statusCode: 400)
                }.name = "user not found"
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
