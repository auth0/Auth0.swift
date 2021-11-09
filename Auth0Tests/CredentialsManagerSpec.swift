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
                    credentialsManager.revoke {
                        expect($0).to(beNil())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should not return an error if there were no credentials stored") {
                _ = credentialsManager.clear()
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke {
                        expect($0).to(beNil())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should not return an error if there is no refresh token, and clear credentials anyway") {
                let credentials = Credentials(
                    accessToken: AccessToken,
                    idToken: IdToken,
                    expiresIn: Date(timeIntervalSinceNow: ExpiresIn)
                    )
                
                _ = credentialsManager.store(credentials: credentials)
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke {
                        expect($0).to(beNil())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should return the failure if the token could not be revoked, and not clear credentials") {
                stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                    return authFailure(code: "400", description: "Revoke failed")
                }
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke {
                        expect($0).to(matchError(
                            CredentialsManagerError.revokeFailed(AuthenticationError(string: "Revoke failed", statusCode: 400))
                        ))
                        
                        expect(credentialsManager.hasValid()).to(beTrue())
                        done()
                    }
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
                    credentialsManager.credentials {
                        expect($0).to(beNil())
                        expect($1!.accessToken) == AccessToken
                        expect($1!.refreshToken) == RefreshToken
                        expect($1!.idToken) == IdToken
                        done()
                    }
                }
                
                waitUntil(timeout: Timeout) { done in
                    secondaryCredentialsManager.credentials {
                        expect($0).to(beNil())
                        expect($1!.accessToken) == "SecondaryAccessToken"
                        expect($1!.refreshToken) == "SecondaryRefreshToken"
                        expect($1!.idToken) == "SecondaryIdToken"
                        done()
                    }
                }

            }
            
            it("should store new credentials") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                _ = credentialsManager.store(credentials: credentials)
            }
            
            it("should share a space in the keychain if using the same store key") {
                
                credentialsManager = CredentialsManager(authentication: authentication, storeKey: "secondary_store")
                
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials {
                        expect($0).to(beNil())
                        expect($1!.accessToken) == AccessToken
                        expect($1!.refreshToken) == RefreshToken
                        expect($1!.idToken) == IdToken
                        done()
                    }
                }

                waitUntil(timeout: Timeout) { done in
                    secondaryCredentialsManager.credentials {
                        expect($0).to(beNil())
                        expect($1!.accessToken) == AccessToken
                        expect($1!.refreshToken) == RefreshToken
                        expect($1!.idToken) == IdToken
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

            it("should have valid credentials when token valid and no refresh token present") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }

            it("should have valid credentials when token expired and refresh token present") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }

            it("should not have valid credentials when token expired and no refresh token present") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beFalse())
            }

            it("should have valid credentials when the ttl is less than the token lifetime") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid(minTTL: ValidTTL)).to(beTrue())
            }

            it("should have valid credentials when the ttl is greater than the token lifetime and refresh token present") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid(minTTL: InvalidTTL)).to(beTrue())
            }

            it("should not have valid credentials when the ttl is greater than the token lifetime and no refresh token present") {
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

            var error: Error?
            var newCredentials: Credentials?

            beforeEach {
                error = nil
                newCredentials = nil
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) {
                    _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: nil, expiresIn: 86400)
                }.name = "renew success"
            }

            afterEach {
                A0SimpleKeychain().clearAll()
            }

            it("should error when no credentials stored") {
                A0SimpleKeychain().clearAll()
                credentialsManager.credentials { error = $0; newCredentials = $1 }
                expect(error).to(matchError(CredentialsManagerError.noCredentials))
                expect(newCredentials).toEventually(beNil())
            }

            it("should error when token expired") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)
                credentialsManager.credentials { error = $0; newCredentials = $1 }
                expect(error).to(matchError(CredentialsManagerError.noCredentials))
                expect(newCredentials).toEventually(beNil())
            }

            it("should return original credentials as not expired") {
                _ = credentialsManager.store(credentials: credentials)
                credentialsManager.credentials { error = $0; newCredentials = $1 }
                expect(error).to(beNil())
                expect(newCredentials).toEventuallyNot(beNil())
            }

            #if os(iOS)
            context("require touch") {

                beforeEach {
                    credentialsManager.enableBiometrics(withTitle: "Auth Title", cancelTitle: "Cancel Title", fallbackTitle: "Fallback Title")
                }

                it("should error when touch unavailable") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(matchError(CredentialsManagerError.touchFailed(LAError(LAError.touchIDNotAvailable))))
                            expect(newCredentials).to(beNil())
                            done()
                        }
                    }
                }
            }
            #endif

            context("renew") {

                it("should yield new credentials without refresh token rotation") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == NewAccessToken
                            expect(newCredentials?.refreshToken) == RefreshToken
                            expect(newCredentials?.idToken) == NewIdToken
                            done()
                        }
                    }
                }
                
                it("should yield new credentials with refresh token rotation") {
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: 86400)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == NewAccessToken
                            expect(newCredentials?.refreshToken) == NewRefreshToken
                            expect(newCredentials?.idToken) == NewIdToken
                            done()
                        }
                    }
                }
                
                it("should store new credentials") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(beNil())
                            credentialsManager.credentials {
                                expect($1?.accessToken) == NewAccessToken
                                expect($1?.refreshToken) == RefreshToken
                                expect($1?.idToken) == NewIdToken
                                done()
                            }
                        }
                    }
                }

                it("should yield error on failed renew") {
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in return authFailure(code: "invalid_request", description: "missing_params") }.name = "renew failed"
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(matchError(CredentialsManagerError.failedRefresh(AuthenticationError())))
                            expect(newCredentials).to(beNil())
                            done()
                        }
                    }
                }

                it("request should include custom parameters on renew") {
                    let someId = UUID().uuidString
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "some_id": someId])) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: 86400)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(parameters: ["some_id": someId]) { error = $0; newCredentials = $1
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == NewAccessToken
                            expect(newCredentials?.refreshToken) == NewRefreshToken
                            expect(newCredentials?.idToken) == NewIdToken
                            done()
                        }
                    }
                }
            }

            context("forced renew") {

                it("should not yield a new access token by default") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { error, newCredentials in
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == AccessToken
                            done()
                        }
                    }
                }

                it("should not yield a new access token without a new scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil) { error, newCredentials in
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == AccessToken
                            done()
                        }
                    }
                }

                it("should not yield a new access token with the same scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile") { error, newCredentials in
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == AccessToken
                            done()
                        }
                    }
                }

                it("should yield a new access token with a new scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile offline_access")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile") { error, newCredentials in
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == NewAccessToken
                            done()
                        }
                    }
                }

                it("should not yield a new access token with a min ttl less than its expiry") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil, minTTL: ValidTTL) { error, newCredentials in
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == AccessToken
                            done()
                        }
                    }
                }

                it("should yield a new access token with a min ttl greater than its expiry") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil, minTTL: InvalidTTL) { error, newCredentials in
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == NewAccessToken
                            done()
                        }
                    }
                }

                it("should fail to yield a renewed access token with a min ttl greater than its expiry") {
                    let minTTL = 100_000
                    let expectedError = CredentialsManagerError.failedRefresh(NSError(domain: "The lifetime of the renewed Access Token (\(ExpiresIn)s) is less than minTTL requested (\(minTTL)s). Increase the 'Token Expiration' setting of your Auth0 API in the dashboard or request a lower minTTL",
                        code: -99999,
                        userInfo: nil))
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil, minTTL: minTTL) { error, newCredentials in
                            expect(error).to(matchError(expectedError))
                            expect(newCredentials).to(beNil())
                            done()
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
    }
}

