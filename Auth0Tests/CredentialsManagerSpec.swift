import Combine
import Quick
import Nimble
import SimpleKeychain
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
#if WEB_AUTH_PLATFORM
import LocalAuthentication
#endif

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let TokenType = "bearer"
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewIdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewRefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ExpiresIn: TimeInterval = 3600
private let ValidTTL = Int(ExpiresIn - 1000)
private let InvalidTTL = Int(ExpiresIn + 1000)
private let Timeout: DispatchTimeInterval = .seconds(2)
private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"
private let ExpiredToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiIiLCJpYXQiOjE1NzE4NTI0NjMsImV4cCI6MTU0MDIzMDA2MywiYXVkIjoiYXVkaWVuY2UiLCJzdWIiOiIxMjM0NSJ9.Lcz79P1AFAZDI4Yr1teFapFVAmBbdfhGBGbj9dQVeRM"
private let ValidToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ0ZXN0IiwiaWF0IjoxNTcxOTExNTkyLCJleHAiOjE5MTg5ODAzOTIsImF1ZCI6ImF1ZGllbmNlIiwic3ViIjoic3VifDEyMyJ9.uLNF8IpY6cJTY-RyO3CcqLpCaKGaVekR-DTDoQTlnPk" // Token is valid until 2030

class CredentialsManagerSpec: QuickSpec {

    override func spec() {

        let authentication = Auth0.authentication(clientId: ClientId, domain: Domain)
        var credentialsManager: CredentialsManager!
        var credentials: Credentials!

        beforeEach {
            credentialsManager = CredentialsManager(authentication: authentication)
            credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
            stub(condition: isHost(Domain)) { _ in catchAllResponse() }.name = "YOU SHALL NOT PASS!"
        }

        afterEach {
            HTTPStubs.removeAllStubs()
        }

        describe("storage") {

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should store credentials in keychain") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
            }

            it("should clear credentials in keychain") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.clear()).to(beTrue())
            }

            it("should fail to clear credentials") {
                expect(credentialsManager.clear()).to(beFalse())
            }
        }

        describe("custom storage") {

            class CustomStore: CredentialsStorage {
                var store: [String: Data] = [:]
                func getEntry(forKey: String) -> Data? {
                    return store[forKey]
                }
                func setEntry(_ data: Data, forKey: String) -> Bool {
                    store[forKey] = data
                    return true
                }
                func deleteEntry(forKey: String) -> Bool {
                    store[forKey] = nil
                    return true
                }
            }
            
            beforeEach {
                credentialsManager = CredentialsManager(authentication: authentication, storage: CustomStore());
            }
            
            afterEach {
                _ = credentialsManager.clear()
            }

            it("should store credentials in custom store") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }

            it("should clear credentials from custom store") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.clear()).to(beTrue())
                expect(credentialsManager.hasValid()).to(beFalse())
            }
        }

        describe("clearing and revoking refresh token") {
            
            beforeEach {
                _ = credentialsManager.store(credentials: credentials)
                
                stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in return revokeTokenResponse() }.name = "revoke success"
            }
            
            afterEach {
                _ = credentialsManager.clear()
            }
            
            it("should clear credentials and revoke the refresh token") {
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(beSuccessful())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should not return an error if there were no credentials stored") {
                _ = credentialsManager.clear()
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(beSuccessful())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should not return an error if there is no refresh token, and clear credentials anyway") {
                let credentials = Credentials(accessToken: AccessToken,
                                              idToken: IdToken,
                                              expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                
                _ = credentialsManager.store(credentials: credentials)
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(beSuccessful())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should return the failure if the token could not be revoked, and not clear credentials") {
                let cause = AuthenticationError(description: "Revoke failed", statusCode: 400)
                let expectedError = CredentialsManagerError(code: .revokeFailed, cause: cause)
                stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                    return authFailure(code: "400", description: "Revoke failed")
                }
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(haveCredentialsManagerError(expectedError))
                        expect(credentialsManager.hasValid()).to(beTrue())
                        done()
                    }
                }
            }
            
            it("should include custom headers") {
                stub(condition: hasHeader("foo", value: "bar")) { _ in return revokeTokenResponse() }.name = "revoke success"
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke(headers: ["foo": "bar"], { result in
                        expect(result).to(beSuccessful())
                        done()
                    })
                }
            }
        }
        
        describe("multi instances of credentials manager") {
            
            var secondaryCredentialsManager: CredentialsManager!
            var secondaryCredentials: Credentials!

            beforeEach {
                secondaryCredentialsManager = CredentialsManager(authentication: authentication, storeKey: "secondary_store")
                secondaryCredentials = Credentials(accessToken: "SecondaryAccessToken", tokenType: TokenType, idToken: "SecondaryIdToken", refreshToken: "SecondaryRefreshToken", expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
            }
            
            it("should store credentials into distinct locations") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(secondaryCredentialsManager.store(credentials: secondaryCredentials)).to(beTrue())
                                
                waitUntil(timeout: .seconds(200)) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken, RefreshToken))
                        done()
                    }
                }
                
                waitUntil(timeout: Timeout) { done in
                    secondaryCredentialsManager.credentials { result in
                        expect(result).to(haveCredentials("SecondaryAccessToken", "SecondaryIdToken", "SecondaryRefreshToken"))
                        done()
                    }
                }

            }
            
            it("should store new credentials") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)
            }
            
            it("should share a space in the keychain if using the same store key") {
                
                credentialsManager = CredentialsManager(authentication: authentication, storeKey: "secondary_store")
                
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken, RefreshToken))
                        done()
                    }
                }

                waitUntil(timeout: Timeout) { done in
                    secondaryCredentialsManager.credentials { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken, RefreshToken))
                        done()
                    }
                }

            }

            afterEach {
                _ = credentialsManager.clear()
                _ = secondaryCredentialsManager.clear()
            }
            
        }

        describe("user") {
            
            afterEach {
                _ = credentialsManager.clear()
            }

            it("should retrieve the user profile when there is an id token stored") {
                let credentials = Credentials(idToken: ValidToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.user).toNot(beNil())
            }

            it("should not retrieve the user profile when there are no credentials stored") {
                expect(credentialsManager.user).to(beNil())
            }

            it("should not retrieve the user profile when the id token is not a jwt") {
                let credentials = Credentials(accessToken: AccessToken, idToken: "not a jwt", expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.user).to(beNil())
            }
            
        }

        describe("validity") {

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should have valid credentials when stored and not expired") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }

            it("should not have valid credentials when keychain empty") {
                expect(credentialsManager.hasValid()).to(beFalse())
            }

            it("should have valid credentials when token valid") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }

            it("should not have valid credentials when token expired") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beFalse())
            }

            it("should have valid credentials when the ttl is less than the token lifetime") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid(minTTL: ValidTTL)).to(beTrue())
            }

            it("should not have valid credentials when the ttl is greater than the token lifetime") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid(minTTL: InvalidTTL)).to(beFalse())
            }

        }

        describe("expiry") {

            it("should not expire soon when the min ttl is less than the at expiry") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.willExpire(credentials, within: ValidTTL)).to(beFalse())
            }

            it("should expire soon when the min ttl is greater than the at expiry") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.willExpire(credentials, within: InvalidTTL)).to(beTrue())
            }

            it("should not be expired when expiry of at is + 1 hour") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.hasExpired(credentials)).to(beFalse())
            }

            it("should be expired when expiry of at is - 1 hour") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                expect(credentialsManager.hasExpired(credentials)).to(beTrue())
            }

        }

        describe("scope") {

            it("should return true when the scope has changed") {
                let credentials = Credentials(scope: "openid email profile")
                expect(credentialsManager.hasScopeChanged(credentials, from: "openid email")).to(beTrue())
            }

            it("should return false when the scope has not changed") {
                let credentials = Credentials(scope: "openid email")
                expect(credentialsManager.hasScopeChanged(credentials, from: "openid email")).to(beFalse())
                expect(credentialsManager.hasScopeChanged(credentials, from: "email openid")).to(beFalse())
            }

        }

        describe("id token") {

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should be valid when at valid and id token expired") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: ExpiredToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }

        }

        describe("retrieval") {

            beforeEach {
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) {
                    _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: nil, expiresIn: ExpiresIn * 2)
                }.name = "renew success"
            }

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should error when no credentials stored") {
                _ = credentialsManager.clear()

                waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noCredentials)))
                        done()
                    }
                }
            }

            it("should error when no refresh token") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)

                waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noRefreshToken)))
                        done()
                    }
                }
            }

            it("should return original credentials as not expired") {
                _ = credentialsManager.store(credentials: credentials)

                waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            #if os(iOS)
            context("require touch") {

                beforeEach {
                    credentialsManager.enableBiometrics(withTitle: "Auth Title", cancelTitle: "Cancel Title", fallbackTitle: "Fallback Title")
                }

                it("should error when touch unavailable") {
                    let cause = LAError(LAError.biometryNotAvailable)
                    let expectedError = CredentialsManagerError(code: .biometricsFailed, cause: cause)
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }
            }
            #endif

            context("renew") {

                it("should yield new credentials without refresh token rotation") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, RefreshToken))
                            done()
                        }
                    }
                }
                
                it("should yield new credentials with refresh token rotation") {
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            done()
                        }
                    }
                }
                
                it("should store new credentials") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beSuccessful())
                            credentialsManager.credentials { result in
                                expect(result).to(haveCredentials(NewAccessToken, NewIdToken, RefreshToken))
                                done()
                            }
                        }
                    }
                }

                it("should yield error on failed renew") {
                    let cause = AuthenticationError(info: ["error": "invalid_request", "error_description": "missing_params"])
                    let expectedError = CredentialsManagerError(code: .renewFailed, cause: cause)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in return authFailure(code: "invalid_request", description: "missing_params") }.name = "renew failed"
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

                it("request should include custom parameters on renew") {
                    let someId = UUID().uuidString
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "some_id": someId])) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(parameters: ["some_id": someId]) { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            done()
                        }
                    }
                }

                it("should include custom headers") {
                    stub(condition: hasHeader("foo", value: "bar")) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(headers: ["foo": "bar"]) { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
            }

            context("forced renew") {

                beforeEach {
                    _ = credentialsManager.store(credentials: credentials)
                }

                it("should not yield a new access token by default") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should not yield a new access token without a new scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil) { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should not yield a new access token with the same scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile") { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should yield a new access token with a new scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile offline_access") { result in
                            expect(result).to(haveCredentials(NewAccessToken))
                            done()
                        }
                    }
                }

                it("should not yield a new access token with a min ttl less than its expiry") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(minTTL: ValidTTL) { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should yield a new access token with a min ttl greater than its expiry") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(minTTL: InvalidTTL) { result in
                            expect(result).to(haveCredentials(NewAccessToken))
                            done()
                        }
                    }
                }

                it("should fail to yield a renewed access token with a min ttl greater than its expiry") {
                    let minTTL = 100_000
                    // The dates are not mocked, so they won't match exactly
                    let expectedError = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: Int(ExpiresIn - 1)))
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: nil, expiresIn: ExpiresIn)
                    }
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil, minTTL: minTTL) { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

            }

            context("serial renew from same thread") {

                it("should yield the stored credentials after the previous renewal operation succeeded") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                        }
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            done()
                        }
                    }
                }

                it("should renew the credentials after the previous renewal operation failed") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in return apiFailureResponse() }
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beFailure())
                            stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                                return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                            }
                        }
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials())
                            done()
                        }
                    }
                }

            }

            context("serial renew from different threads") {

                it("should yield the stored credentials after the previous renewal operation succeeded") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "request": "first"])) { request in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    waitUntil(timeout: Timeout) { done in
                        DispatchQueue.global(qos: .utility).sync {
                            credentialsManager.credentials(parameters: ["request": "first"]) { result in
                                expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            }
                        }
                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager.credentials { result in
                                expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                                done()
                            }
                        }
                    }
                }

                it("should renew the credentials after the previous renewal operation failed") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "request": "first"])) { request in
                        return apiFailureResponse()
                    }
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "request": "second"])) { request in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    waitUntil(timeout: Timeout) { done in
                        DispatchQueue.global(qos: .utility).sync {
                            credentialsManager.credentials(parameters: ["request": "first"]) { result in
                                expect(result).to(beFailure())
                            }
                        }
                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager.credentials(parameters: ["request": "second"]) { result in
                                expect(result).to(haveCredentials())
                                done()
                            }
                        }
                    }
                }

            }

            context("custom keychain") {
                let storage = A0SimpleKeychain(service: "test_service")
                beforeEach {
                    credentialsManager = CredentialsManager(authentication: authentication,
                                                            storage: storage)
                }

                it("custom keychain should successfully set and clear credentials") {
                    _ = credentialsManager.store(credentials: credentials)
                    expect(storage.data(forKey: "credentials")).toNot(beNil())
                    _ = credentialsManager.clear()
                    expect(storage.data(forKey: "credentials")).to(beNil())
                }
            }
        }

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            describe("combine") {
                var cancellables: Set<AnyCancellable> = []

                afterEach {
                    _ = credentialsManager.clear()
                    cancellables.removeAll()
                }

                context("credentials") {

                    it("should emit only one value") {
                        _ = credentialsManager.store(credentials: credentials)
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .credentials()
                                .assertNoFailure()
                                .count()
                                .sink(receiveValue: { count in
                                    expect(count) == 1
                                    done()
                                })
                                .store(in: &cancellables)
                        }
                    }

                    it("should complete using the default parameter values") {
                        _ = credentialsManager.store(credentials: credentials)
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .credentials()
                                .sink(receiveCompletion: { completion in
                                    guard case .finished = completion else { return }
                                    done()
                                }, receiveValue: { _ in })
                                .store(in: &cancellables)
                        }
                    }

                    it("should complete using custom parameter values") {
                        stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "foo": "bar"]) && hasHeader("foo", value: "bar")) { _ in
                            return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                        }
                        credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn), scope: "openid profile")
                        _ = credentialsManager.store(credentials: credentials)
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .credentials(withScope: "openid profile offline_access",
                                             minTTL: ValidTTL,
                                             parameters: ["foo": "bar"],
                                             headers: ["foo": "bar"])
                                .sink(receiveCompletion: { completion in
                                    guard case .finished = completion else { return }
                                    done()
                                }, receiveValue: { _ in })
                                .store(in: &cancellables)
                        }
                    }

                    it("should complete with an error") {
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .credentials()
                                .ignoreOutput()
                                .sink(receiveCompletion: { completion in
                                    guard case .failure = completion else { return }
                                    done()
                                }, receiveValue: { _ in })
                                .store(in: &cancellables)
                        }
                    }

                }

                context("revoke") {

                    it("should emit only one value") {
                        stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                            return revokeTokenResponse()
                        }
                        _ = credentialsManager.store(credentials: credentials)
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .revoke()
                                .assertNoFailure()
                                .count()
                                .sink(receiveValue: { count in
                                    expect(count) == 1
                                    done()
                                })
                                .store(in: &cancellables)
                        }
                    }

                    it("should complete using the default parameter values") {
                        stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                            return revokeTokenResponse()
                        }
                        _ = credentialsManager.store(credentials: credentials)
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .revoke()
                                .sink(receiveCompletion: { completion in
                                    guard case .finished = completion else { return }
                                    done()
                                }, receiveValue: { _ in })
                                .store(in: &cancellables)
                        }
                    }

                    it("should complete using custom parameter values") {
                        stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken]) && hasHeader("foo", value: "bar")) { _ in
                            return revokeTokenResponse()
                        }
                        _ = credentialsManager.store(credentials: credentials)
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .revoke(headers: ["foo": "bar"])
                                .sink(receiveCompletion: { completion in
                                    guard case .finished = completion else { return }
                                    done()
                                }, receiveValue: { _ in })
                                .store(in: &cancellables)
                        }
                    }

                    it("should complete with an error") {
                        stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                            return apiFailureResponse()
                        }
                        _ = credentialsManager.store(credentials: credentials)
                        waitUntil(timeout: Timeout) { done in
                            credentialsManager
                                .revoke()
                                .ignoreOutput()
                                .sink(receiveCompletion: { completion in
                                    guard case .failure = completion else { return }
                                    done()
                                }, receiveValue: { _ in })
                                .store(in: &cancellables)
                        }
                    }

                }

            }
        }

        #if compiler(>=5.5) && canImport(_Concurrency)
        describe("async await") {

            afterEach {
                _ = credentialsManager.clear()
            }

            context("credentials") {

                it("should return the credentials using the default parameter values") {
                    let credentialsManager = credentialsManager!
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        #if compiler(>=5.5.2)
                        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                            Task.init {
                                _ = try await credentialsManager.credentials()
                                done()
                            }
                        }
                        #else
                        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                            Task.init {
                                _ = try await credentialsManager.credentials()
                                done()
                            }
                        } else {
                            done()
                        }
                        #endif
                    }
                }

                it("should return the credentials using custom parameter values") {
                    let credentialsManager = credentialsManager!
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "foo": "bar"]) && hasHeader("foo", value: "bar")) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        #if compiler(>=5.5.2)
                        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                            Task.init {
                                _ = try await credentialsManager.credentials(withScope: "openid profile offline_access",
                                                                             minTTL: ValidTTL,
                                                                             parameters: ["foo": "bar"],
                                                                             headers: ["foo": "bar"])
                                done()
                            }
                        }
                        #else
                        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                            Task.init {
                                _ = try await credentialsManager.credentials(withScope: "openid profile offline_access",
                                                                             minTTL: ValidTTL,
                                                                             parameters: ["foo": "bar"],
                                                                             headers: ["foo": "bar"])
                                done()
                            }
                        } else {
                            done()
                        }
                        #endif
                    }
                }

                it("should throw an error") {
                    let credentialsManager = credentialsManager!
                    waitUntil(timeout: Timeout) { done in
                        #if compiler(>=5.5.2)
                        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                            Task.init {
                                do {
                                    _ = try await credentialsManager.credentials()
                                } catch {
                                    done()
                                }
                            }
                        }
                        #else
                        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                            Task.init {
                                do {
                                    _ = try await credentialsManager.credentials()
                                } catch {
                                    done()
                                }
                            }
                        } else {
                            done()
                        }
                        #endif
                    }
                }

            }

            context("revoke") {

                it("should revoke using the default parameter values") {
                    let credentialsManager = credentialsManager!
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                        return revokeTokenResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        #if compiler(>=5.5.2)
                        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                            Task.init {
                                _ = try await credentialsManager.revoke()
                                done()
                            }
                        }
                        #else
                        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                            Task.init {
                                _ = try await credentialsManager.revoke()
                                done()
                            }
                        } else {
                            done()
                        }
                        #endif
                    }
                }

                it("should revoke using custom parameter values") {
                    let credentialsManager = credentialsManager!
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken]) && hasHeader("foo", value: "bar")) { _ in
                        return revokeTokenResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        #if compiler(>=5.5.2)
                        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                            Task.init {
                                _ = try await credentialsManager.revoke(headers: ["foo": "bar"])
                                done()
                            }
                        }
                        #else
                        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                            Task.init {
                                _ = try await credentialsManager.revoke(headers: ["foo": "bar"])
                                done()
                            }
                        } else {
                            done()
                        }
                        #endif
                    }
                }

                it("should throw an error") {
                    let credentialsManager = credentialsManager!
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                        return apiFailureResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        #if compiler(>=5.5.2)
                        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                            Task.init {
                                do {
                                    _ = try await credentialsManager.revoke()
                                } catch {
                                    done()
                                }
                            }
                        }
                        #else
                        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                            Task.init {
                                do {
                                    _ = try await credentialsManager.revoke()
                                } catch {
                                    done()
                                }
                            }
                        } else {
                            done()
                        }
                        #endif
                    }
                }

            }

        }
        #endif

    }
}
