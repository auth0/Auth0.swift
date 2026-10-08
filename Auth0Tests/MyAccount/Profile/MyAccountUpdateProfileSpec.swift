import Foundation
import Quick
import Nimble

@testable import Auth0

private let UpdateDomain = "samples.auth0.com"
private let UpdateAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let UpdateTimeout: NimbleTimeInterval = .seconds(2)

// MARK: - PATCH /profile

class MyAccountUpdateProfileSpec: QuickSpec {

    override class func spec() {

        let myAccount = Auth0.myAccount(token: UpdateAccessToken, domain: UpdateDomain)

        beforeEach {
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        describe("updateUserProfile") {

            context("success") {

                it("updates given_name, name, and picture") {
                    let updateRequest = UpdateUserProfileRequest(givenName: "Alice",
                                                                 name: "Alice Liddell",
                                                                 picture: "https://example.com/alice.jpg")
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) &&
                        $0.isMethodPATCH &&
                        $0.hasAtLeast(["given_name": "Alice",
                                       "name": "Alice Liddell",
                                       "picture": "https://example.com/alice.jpg"])
                    }, response: fullProfileResponse())

                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(updateRequest).start { result in
                            guard case .success(let profile) = result else {
                                return fail("Expected success, got \(result)")
                            }
                            expect(profile.givenName) == "Alice"
                            done()
                        }
                    }
                }

                it("sends an empty PATCH body as a valid no-op request") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: fullProfileResponse())

                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(UpdateUserProfileRequest()).start { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }

                it("returns the full profile regardless of fields") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: fullProfileResponse())

                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(UpdateUserProfileRequest(nickname: "wonderland")).start { result in
                            guard case .success(let profile) = result else { return fail("Expected success") }
                            expect(profile.email).toNot(beNil())
                            expect(profile.createdAt).toNot(beNil())
                            done()
                        }
                    }
                }

                it("uses async/await") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: fullProfileResponse())

                    waitUntil(timeout: UpdateTimeout) { done in
                        Task {
                            do {
                                let profile = try await myAccount.updateUserProfile(UpdateUserProfileRequest(nickname: "alice")).start()
                                expect(profile.nickname) == "alice"
                            } catch {
                                fail("Expected success, got \(error)")
                            }
                            done()
                        }
                    }
                }

            }

            context("toPayload") {

                it("maps nil metadata values to NSNull") {
                    let request = UpdateUserProfileRequest(userMetadata: ["delete_me": nil, "keep_me": "value"])
                    let payload = request.toPayload
                    let meta = payload["user_metadata"] as? [String: Any]
                    expect(meta?["delete_me"] is NSNull) == true
                    expect(meta?["keep_me"] as? String) == "value"
                }

                it("omits fields that are nil") {
                    let request = UpdateUserProfileRequest(nickname: "alice")
                    let payload = request.toPayload
                    expect(payload["given_name"]).to(beNil())
                    expect(payload["family_name"]).to(beNil())
                    expect(payload["name"]).to(beNil())
                    expect(payload["picture"]).to(beNil())
                    expect(payload["user_metadata"]).to(beNil())
                    expect(payload["nickname"] as? String) == "alice"
                }

                it("produces empty dict for an empty request") {
                    expect(UpdateUserProfileRequest().toPayload).to(beEmpty())
                }

                it("serializes nil metadata values as JSON null") {
                    let request = UpdateUserProfileRequest(userMetadata: ["old_key": nil, "age": 30])
                    let payload = request.toPayload
                    let meta = payload["user_metadata"] as? [String: Any]
                    expect(meta?["old_key"] is NSNull) == true
                    expect(meta?["age"] as? Int) == 30
                }

            }

            context("DPoP") {

                it("uses Bearer when DPoP is not enabled") {
                    let request = myAccount.updateUserProfile(UpdateUserProfileRequest())
                    expect((request as? Request<MyAccountProfile, MyAccountError>)?.headers["Authorization"]) == "Bearer \(UpdateAccessToken)"
                }

                it("uses DPoP when DPoP is enabled") {
                    let request = Auth0.myAccount(token: UpdateAccessToken, domain: UpdateDomain).useDPoP()
                        .updateUserProfile(UpdateUserProfileRequest())
                    expect((request as? Request<MyAccountProfile, MyAccountError>)?.headers["Authorization"]) == "DPoP \(UpdateAccessToken)"
                }

                it("passes DPoP instance to PATCH request") {
                    let request = Auth0.myAccount(token: UpdateAccessToken, domain: UpdateDomain).useDPoP()
                        .updateUserProfile(UpdateUserProfileRequest())
                    expect((request as? Request<MyAccountProfile, MyAccountError>)?.dpop).toNot(beNil())
                }

            }

            context("errors") {

                it("fails with 400 read_only_field and surfaces validation errors") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: readOnlyFieldErrorResponse())

                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(UpdateUserProfileRequest(givenName: "Alice")).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 400
                            expect(error.title) == "read_only_field"
                            expect(error.validationErrors?.first?.pointer) == "/given_name"
                            expect(error.validationErrors?.first?.source) == "managed_by_identity_provider"
                            done()
                        }
                    }
                }

                it("fails with 401") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-401-0001",
                                                      status: 401,
                                                      title: "Unauthorized",
                                                      detail: "Missing or invalid token.",
                                                      statusCode: 401))
                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(UpdateUserProfileRequest()).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 401
                            done()
                        }
                    }
                }

                it("fails with 403") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-403-0002",
                                                      status: 403,
                                                      title: "insufficient_scope",
                                                      detail: "Token lacks required scope.",
                                                      statusCode: 403))
                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(UpdateUserProfileRequest()).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 403
                            done()
                        }
                    }
                }

                it("fails with 404 when feature flag is off") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-404-0001",
                                                      status: 404,
                                                      title: "Not Found",
                                                      detail: "The profile endpoint is not enabled.",
                                                      statusCode: 404))
                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(UpdateUserProfileRequest()).start { result in
                            guard case .failure(let error) = result else { return fail("Expected failure") }
                            expect(error.statusCode) == 404
                            done()
                        }
                    }
                }

                it("fails with 429") {
                    NetworkStub.addStub(condition: {
                        $0.isMyAccountProfile(UpdateDomain, token: UpdateAccessToken) && $0.isMethodPATCH
                    }, response: profileErrorResponse(type: "https://auth0.com/api-errors/A0E-429-0001",
                                                      status: 429,
                                                      title: "Too Many Requests",
                                                      detail: "Rate limit exceeded.",
                                                      statusCode: 429))
                    waitUntil(timeout: UpdateTimeout) { done in
                        myAccount.updateUserProfile(UpdateUserProfileRequest()).start { result in
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
