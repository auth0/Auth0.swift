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
                    let options = GetUserProfileOptions(fields: ["profile_policy"],
                                                        includeFields: false)
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) &&
                        $0.isMethodGET &&
                        $0.hasQueryParameters(["fields": "profile_policy",
                                               "include_fields": "false"])
                    }, response: partialProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: options).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("sends only fields when includeFields is nil") {
                    let options = GetUserProfileOptions(fields: ["given_name", "email"])
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) &&
                        $0.isMethodGET &&
                        $0.hasQueryParameters(["fields": "given_name,email"])
                    }, response: partialProfileResponse())

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: options).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("should decode unknown policy values when the server returns unrecognized access and source values") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: apiSuccessResponse(json: [
                        "given_name": "Alice",
                        "profile_policy": [
                            "/given_name": ["access": "step_up_required", "source": "tenant_admin"],
                            "/nickname": ["access": "read_write", "source": "user"]
                        ] as [String: Any]
                    ]))

                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .success(let profile) = result else {
                                return fail("Expected success, got \(result)")
                            }
                            expect(profile.givenName) == "Alice"
                            expect(profile.profilePolicy?["/given_name"]?.access) == .unknown("step_up_required")
                            expect(profile.profilePolicy?["/given_name"]?.source) == .unknown("tenant_admin")
                            expect(profile.profilePolicy?["/nickname"]?.access) == .readWrite
                            expect(profile.profilePolicy?["/nickname"]?.source) == .user
                            done()
                        }
                    }
                }

                it("should expose the raw value when the policy value is known or unknown") {
                    expect(ProfileFieldAccess.readOnly.rawValue) == "read_only"
                    expect(ProfileFieldAccess.unknown("read_only")) == .readOnly
                    expect(ProfileFieldAccess(rawValue: "other")) == .unknown("other")
                    expect(ProfileFieldSource.idp.rawValue) == "idp"
                    expect(ProfileFieldSource.unknown("idp")) == .idp
                    expect(ProfileFieldSource(rawValue: "other")) == .unknown("other")
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
                            expect(error.code).to(endWith("A0E-403-0002"))
                            done()
                        }
                    }
                }

                it("fails with 403 when the token is not entitled (feature flag off)") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(ProfileDomain, token: ProfileAccessToken) && $0.isMethodGET
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-403-0003",
                                                      status: 403,
                                                      title: "not_entitled",
                                                      detail: "Not entitled to this resource.",
                                                      statusCode: 403))
                    waitUntil(timeout: ProfileTimeout) { done in
                        myAccount.getUserProfile(options: nil).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 403
                            expect(error.code).to(endWith("A0E-403-0003"))
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
        "profile_policy": [
            "/given_name": ["access": "read_only", "source": "idp",
                            "reason": "managed_by_identity_provider"],
            "/family_name": ["access": "read_only", "source": "idp",
                             "reason": "managed_by_identity_provider"],
            "/nickname": ["access": "read_write", "source": "user"],
            "/picture": ["access": "read_write", "source": "user"],
            "/email": ["access": "read_only", "source": "idp",
                       "reason": "managed_via_me_identifiers"],
            "/email_verified": ["access": "read_only", "source": "idp",
                                "reason": "managed_via_me_identifiers"],
            "/phone_number": ["access": "read_only", "source": "user",
                              "reason": "managed_via_me_identifiers"],
            "/phone_verified": ["access": "read_only", "source": "user",
                                "reason": "managed_via_me_identifiers"],
            "/username": ["access": "read_only", "source": "user",
                          "reason": "managed_via_me_identifiers"],
            "/created_at": ["access": "read_only", "source": "system",
                            "reason": "system_field"],
            "/updated_at": ["access": "read_only", "source": "system",
                            "reason": "system_field"]
        ] as [String: Any]
    ])
}

func partialProfileResponse() -> RequestResponse {
    return apiSuccessResponse(json: [
        "email": "alice@example.com",
        "user_id": "google-oauth2|103547991597142817347"
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
