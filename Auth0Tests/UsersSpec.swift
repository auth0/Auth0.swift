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

class UsersSpec: QuickSpec {

    override func spec() {

        let users = Auth0.users(token: Token, domain: Domain)

        afterEach {
            HTTPStubs.removeAllStubs()
            stub(condition: isHost(Domain)) { _ in HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil)) }
                .name = "YOU SHALL NOT PASS!"
        }

        describe("GET /users/:identifier") {

            beforeEach {
                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasBearerToken(Token))
                { _ in managementResponse(["user_id": UserId, "email": SupportAtAuth0]) }
                .name = "User Fetch"

                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasQueryParameters(["fields": "user_id", "include_fields": "true"]) && hasBearerToken(Token))
                { _ in managementResponse(["user_id": UserId]) }
                .name = "User Fetch including fields"

                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodGET() && hasQueryParameters(["fields": "user_id", "include_fields": "false"]) && hasBearerToken(Token))
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
                stub(condition: isUsersPath(Domain, identifier: NonExistentUser) && isMethodGET() && hasBearerToken(Token)) { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}.name = "user not found"
                waitUntil(timeout: Timeout) { done in
                    users.get(NonExistentUser).start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }
        }

        describe("PATCH /users/:identifier") {

            it("should send attributes") {
                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodPATCH() && hasAllOf(["username": Support, "connection": "facebook"]) && hasBearerToken(Token))
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
                stub(condition: isUsersPath(Domain, identifier: UserId) && isMethodPATCH() && hasUserMetadata(metadata) && hasBearerToken(Token))
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
                stub(condition: isUsersPath(Domain, identifier: NonExistentUser) && isMethodPATCH() && hasBearerToken(Token)) { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}.name = "user not found"
                waitUntil(timeout: Timeout) { done in
                    users.patch(NonExistentUser, attributes: UserPatchAttributes().blocked(true)).start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

        }

        describe("PATCH /users/:identifier/identities") {

            it("shoud link with just a token") {
                stub(condition: isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["link_with": "token"]) && hasBearerToken(Token))
                { _ in managementResponse([["user_id": UserId, "email": SupportAtAuth0]])}.name = "user linked"
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withOtherUserToken: "token").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("shoud link without a token") {
                stub(condition: isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["user_id": "other_id", "provider": "facebook"]) && hasBearerToken(Token))
                { _ in managementResponse([["user_id": UserId, "email": SupportAtAuth0]])}.name = "user linked"
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: "facebook").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("shoud link without a token specifying a connection id") {
                stub(condition: isLinkPath(Domain, identifier: UserId) && isMethodPOST() && hasAllOf(["user_id": "other_id", "provider": "facebook", "connection_id": "conn_1"]) && hasBearerToken(Token))
                { _ in managementResponse([["user_id": UserId, "email": SupportAtAuth0]])}.name = "user linked"
                waitUntil(timeout: Timeout) { done in
                    users.link(UserId, withUser: "other_id", provider: "facebook", connectionId: "conn_1").start { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should fail request") {
                stub(condition: isLinkPath(Domain, identifier: NonExistentUser) && isMethodPOST() && hasBearerToken(Token))
                { _ in managementErrorResponse(error: "not_found", description: "not found user", code: "user_not_found", statusCode: 400)}.name = "user not found"
                waitUntil(timeout: Timeout) { done in
                    users.link(NonExistentUser, withOtherUserToken: "token").start { result in
                        expect(result).to(haveManagementError("not_found", description: "not found user", code: "user_not_found", statusCode: 400))
                        done()
                    }
                }
            }

        }
    }

}
