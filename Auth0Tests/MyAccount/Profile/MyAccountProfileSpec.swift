import Foundation
import Quick
import Nimble

@testable import Auth0

private let ProfileDomain = "samples.auth0.com"
private let ProfileAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ProfileTimeout: NimbleTimeInterval = .seconds(2)

// MARK: - GET /profile

class MyAccountGetProfileSpec: QuickSpec {

    override class func spec() {

        let myAccount = Auth0.myAccount(token: ProfileAccessToken, domain: ProfileDomain)

        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        describe("getUserProfile") {

            context("success") {

                it("returns all profile fields") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) &&
                        $0.isMethodGET
                    }, response: fullProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .success(let profile) = result else {
                                return fail("Expected success, got \(result)")
                            }
                            expect(profile.userId) == "google-oauth2|103547991597142817347"
                            expect(profile.givenName) == "Alice"
                            expect(profile.familyName) == "Liddell"
                            expect(profile.name) == "Alice Liddell"
                            expect(profile.nickname) == "alice"
                            expect(profile.picture) == "https://example.com/alice.jpg"
                            expect(profile.email) == "alice@example.com"
                            expect(profile.emailVerified) == true
                            expect(profile.phoneNumber) == "+14155551234"
                            expect(profile.phoneVerified) == false
                            expect(profile.username) == "alice_l"
                            expect(profile.createdAt) == "2026-03-14T09:12:04.000Z"
                            expect(profile.updatedAt) == "2026-08-02T17:41:55.000Z"
                            done()
                        }
                    }
                }

                it("returns profile policy with correct access, source, and reason") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) &&
                        $0.isMethodGET
                    }, response: fullProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .success(let profile) = result else {
                                return fail("Expected success, got \(result)")
                            }
                            expect(profile.profilePolicy?["/nickname"]?.access) == .readWrite
                            expect(profile.profilePolicy?["/nickname"]?.source) == .user
                            expect(profile.profilePolicy?["/nickname"]?.reason).to(beNil())
                            expect(profile.profilePolicy?["/given_name"]?.access) == .readOnly
                            expect(profile.profilePolicy?["/given_name"]?.source) == .idp
                            expect(profile.profilePolicy?["/given_name"]?.reason) == "managed_by_identity_provider"
                            expect(profile.profilePolicy?["/created_at"]?.access) == .readOnly
                            expect(profile.profilePolicy?["/created_at"]?.source) == .system
                            done()
                        }
                    }
                }

                it("decodes user_metadata with mixed value types") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) &&
                        $0.isMethodGET
                    }, response: profileWithRichMetadataResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .success(let profile) = result else {
                                return fail("Expected success, got \(result)")
                            }
                            expect(profile.userMetadata?["theme"] as? String) == "dark"
                            expect(profile.userMetadata?["age"] as? Int) == 30
                            expect(profile.userMetadata?["score"] as? Double) == 9.5
                            expect(profile.userMetadata?["active"] as? Bool) == true
                            expect((profile.userMetadata?["tags"] as? [Any])?.first as? String) == "swift"
                            expect(profile.userMetadata?["nullable"] is NSNull) == true
                            done()
                        }
                    }
                }

                it("sends fields as comma-joined query parameter") {
                    let options = GetUserProfileOptions(fields: ["given_name", "email", "picture"],
                                                        includeFields: true)
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) &&
                        $0.isMethodGET &&
                        $0.hasQueryParameters(["fields": "given_name,email,picture",
                                               "include_fields": "true"])
                    }, response: partialProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: options).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("sends include_fields=false for exclusion mode") {
                    let options = GetUserProfileOptions(fields: ["user_metadata"],
                                                        includeFields: false)
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) &&
                        $0.isMethodGET &&
                        $0.hasQueryParameters(["fields": "user_metadata",
                                               "include_fields": "false"])
                    }, response: partialProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: options).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("omits query parameters when options is nil") {
                    let request = myAccount.getUserProfile(options: nil)
                    let params = (request as? Request<MyAccountProfile, MyAccountError>)?.parameters
                    expect(params?["fields"]).to(beNil())
                    expect(params?["include_fields"]).to(beNil())
                }

                it("omits query parameters when fields is empty") {
                    let request = myAccount.getUserProfile(options: GetUserProfileOptions(fields: [],
                                                                                          includeFields: true))
                    let params = (request as? Request<MyAccountProfile, MyAccountError>)?.parameters
                    expect(params?["fields"]).to(beNil())
                    expect(params?["include_fields"]).to(beNil())
                }

                it("uses the zero-argument convenience overload") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: partialProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile().start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("uses async/await") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: partialProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        Task {
                            do {
                                let profile = try await myAccount.getUserProfile(options: nil).start()
                                expect(profile.email) == "alice@example.com"
                            } catch {
                                fail("Expected success, got \(error)")
                            }
                            done()
                        }
                    }
                }

            }

            context("DPoP") {

                it("uses Bearer when DPoP is not enabled") {
                    let request = myAccount.getUserProfile(options: nil)
                    expect((request as? Request<MyAccountProfile, MyAccountError>)?.headers["Authorization"]) == "Bearer \(ProfileAccessToken)"
                }

                it("uses DPoP when DPoP is enabled") {
                    let request = Auth0.myAccount(token: ProfileAccessToken, domain: ProfileDomain).useDPoP()
                        .getUserProfile(options: nil)
                    expect((request as? Request<MyAccountProfile, MyAccountError>)?.headers["Authorization"]) == "DPoP \(ProfileAccessToken)"
                }

                it("passes DPoP instance to GET request") {
                    let request = Auth0.myAccount(token: ProfileAccessToken, domain: ProfileDomain).useDPoP()
                        .getUserProfile(options: nil)
                    expect((request as? Request<MyAccountProfile, MyAccountError>)?.dpop).toNot(beNil())
                }

            }

            context("errors") {

                it("fails with 400") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-400-0003",
                                                      status: 400,
                                                      title: "validation_error",
                                                      detail: "Invalid request.",
                                                      statusCode: 400))
                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 400
                            done()
                        }
                    }
                }

                it("fails with 401") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-401-0001",
                                                      status: 401,
                                                      title: "Unauthorized",
                                                      detail: "Missing or invalid token.",
                                                      statusCode: 401))
                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 401
                            done()
                        }
                    }
                }

                it("fails with 403") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-403-0002",
                                                      status: 403,
                                                      title: "insufficient_scope",
                                                      detail: "Token lacks required scope.",
                                                      statusCode: 403))
                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 403
                            done()
                        }
                    }
                }

                it("fails with 404 when feature flag is off") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-404-0001",
                                                      status: 404,
                                                      title: "Not Found",
                                                      detail: "The profile endpoint is not enabled.",
                                                      statusCode: 404))
                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 404
                            done()
                        }
                    }
                }

                it("fails with 429") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-429-0001",
                                                      status: 429,
                                                      title: "Too Many Requests",
                                                      detail: "Rate limit exceeded.",
                                                      statusCode: 429))
                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 429
                            done()
                        }
                    }
                }

            }

        }

    }

}

// MARK: - Fixtures (shared)

func fullProfileResponse() -> RequestResponse {
    return apiSuccessResponse(json: [
        "user_id": "google-oauth2|103547991597142817347",
        "given_name": "Alice",
        "family_name": "Liddell",
        "name": "Alice Liddell",
        "nickname": "alice",
        "picture": "https://example.com/alice.jpg",
        "email": "alice@example.com",
        "email_verified": true,
        "phone_number": "+14155551234",
        "phone_verified": false,
        "username": "alice_l",
        "created_at": "2026-03-14T09:12:04.000Z",
        "updated_at": "2026-08-02T17:41:55.000Z",
        "user_metadata": ["theme": "dark"],
        "profile_policy": [
            "/given_name": ["label": "First name", "access": "read_only", "source": "idp",
                            "reason": "managed_by_identity_provider"],
            "/family_name": ["label": "Last name", "access": "read_only", "source": "idp",
                             "reason": "managed_by_identity_provider"],
            "/nickname": ["label": "Nickname", "access": "read_write", "source": "user"],
            "/picture": ["label": "Picture", "access": "read_write", "source": "user"],
            "/email": ["label": "Email", "access": "read_only", "source": "idp",
                       "reason": "managed_via_me_identifiers"],
            "/email_verified": ["label": "Email verified", "access": "read_only", "source": "idp",
                                "reason": "managed_via_me_identifiers"],
            "/phone_number": ["label": "Phone", "access": "read_only", "source": "user",
                              "reason": "managed_via_me_identifiers"],
            "/phone_verified": ["label": "Phone verified", "access": "read_only", "source": "user",
                                "reason": "managed_via_me_identifiers"],
            "/username": ["label": "Username", "access": "read_only", "source": "user",
                          "reason": "managed_via_me_identifiers"],
            "/created_at": ["label": "Created", "access": "read_only", "source": "system",
                            "reason": "system_field"],
            "/updated_at": ["label": "Updated", "access": "read_only", "source": "system",
                            "reason": "system_field"],
            "/user_metadata": ["label": "Preferences", "access": "read_write", "source": "user"]
        ] as [String: Any]
    ])
}

func partialProfileResponse() -> RequestResponse {
    return apiSuccessResponse(json: [
        "email": "alice@example.com",
        "user_id": "google-oauth2|103547991597142817347"
    ])
}

func profileWithRichMetadataResponse() -> RequestResponse {
    return apiSuccessResponse(json: [
        "user_id": "google-oauth2|103547991597142817347",
        "user_metadata": [
            "theme": "dark",
            "age": 30,
            "score": 9.5,
            "active": true,
            "tags": ["swift", "ios"],
            "nullable": NSNull()
        ] as [String: Any]
    ])
}

func profileErrorResponse(type errorType: String,
                          status: Int,
                          title: String,
                          detail: String,
                          statusCode: Int) -> RequestResponse {
    return apiFailureResponse(json: [
        "type": errorType,
        "status": status,
        "title": title,
        "detail": detail
    ], statusCode: statusCode)
}

func readOnlyFieldErrorResponse() -> RequestResponse {
    return apiFailureResponse(json: [
        "type": "https://auth0.com/api-errors/A0E-400-0008",
        "status": 400,
        "title": "read_only_field",
        "detail": "The field '/given_name' is read-only.",
        "validation_errors": [
            [
                "detail": "Field is managed by the identity provider.",
                "pointer": "/given_name",
                "source": "managed_by_identity_provider"
            ]
        ]
    ] as [AnyHashable: Any], statusCode: 400)
}
