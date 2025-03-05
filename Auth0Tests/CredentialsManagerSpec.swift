import Combine
import Quick
import Nimble
import SimpleKeychain
#if WEB_AUTH_PLATFORM
import LocalAuthentication
#endif

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let TokenType = "bearer"
private let NewTokenType = "DPoP"
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewIdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewRefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Audience = "https://example.com/api"
private let Scope = "openid profile email"
private let NewScope = "openid profile email phone"
private let ExpiresIn: TimeInterval = 3600
private let ValidTTL = Int(ExpiresIn - 1000)
private let InvalidTTL = Int(ExpiresIn + 1000)
private let Timeout: NimbleTimeInterval = .seconds(2)
private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"
private let ExpiredToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiIiLCJpYXQiOjE1NzE4NTI0NjMsImV4cCI6MTU0MDIzMDA2MywiYXVkIjoiYXVkaWVuY2UiLCJzdWIiOiIxMjM0NSJ9.Lcz79P1AFAZDI4Yr1teFapFVAmBbdfhGBGbj9dQVeRM"
private let ValidToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ0ZXN0IiwiaWF0IjoxNTcxOTExNTkyLCJleHAiOjE5MTg5ODAzOTIsImF1ZCI6ImF1ZGllbmNlIiwic3ViIjoic3VifDEyMyJ9.uLNF8IpY6cJTY-RyO3CcqLpCaKGaVekR-DTDoQTlnPk" // Token is valid until 2030

class CredentialsManagerSpec: QuickSpec {

    override class func spec() {

        let authentication = Auth0.authentication(clientId: ClientId, domain: Domain)
        var credentialsManager: CredentialsManager!
        var credentials: Credentials!
        var apiCredentials: APICredentials!

        beforeEach {
            credentialsManager = CredentialsManager(authentication: authentication)
            credentials = Credentials(accessToken: AccessToken,
                                      tokenType: TokenType,
                                      idToken: IdToken,
                                      refreshToken: RefreshToken,
                                      expiresIn: Date(timeIntervalSinceNow: ExpiresIn),
                                      scope: Scope)
            apiCredentials = APICredentials(accessToken: AccessToken,
                                            tokenType: TokenType,
                                            expiresIn: Date(timeIntervalSinceNow: -ExpiresIn),
                                            scope: Scope)

            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        describe("storage under the default key") {

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

        describe("storage under multiple keys") {
            let audiences = ["https://example.com/api1", "https://example.com/api2"]

            beforeEach {
                apiCredentials = APICredentials(accessToken: AccessToken,
                                                tokenType: TokenType,
                                                expiresIn: Date(timeIntervalSinceNow: ExpiresIn),
                                                scope: "scope")
            }

            afterEach {
                audiences.forEach { audience in
                    _ = credentialsManager.clear(forAudience: audience)
                }
            }

            it("should store credentials in keychain") {
                let store = SimpleKeychain()
                credentialsManager = CredentialsManager(authentication: authentication, storage: store)

                audiences.forEach { audience in
                    expect(credentialsManager.store(apiCredentials: apiCredentials, forAudience: audience)).to(beTrue())
                    expect(fetchCredentials(from: store)).to(beNil())
                }
            }

            it("should clear credentials in keychain") {
                let store = SimpleKeychain()
                credentialsManager = CredentialsManager(authentication: authentication, storage: store)

                audiences.forEach { audience in
                    expect(credentialsManager.store(apiCredentials: apiCredentials, forAudience: audience)).to(beTrue())
                    expect(credentialsManager.clear(forAudience: audience)).to(beTrue())
                    expect(fetchAPICredentials(forAudience: audience, from: store)).to(beNil())
                }
            }

            it("should fail to clear credentials") {
                audiences.forEach { audience in
                    expect(credentialsManager.clear(forAudience: audience)).to(beFalse())
                }
            }

        }

        describe("custom storage") {

            class CustomStore: CredentialsStorage {
                var store: [String: Data] = [:]
                func getEntry(forKey key: String) -> Data? {
                    return store[key]
                }
                func setEntry(_ data: Data, forKey key: String) -> Bool {
                    store[key] = data
                    return true
                }
                func deleteEntry(forKey key: String) -> Bool {
                    store[key] = nil
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

        describe("custom keychain") {
            let storage = SimpleKeychain(service: "test_service")

            beforeEach {
                credentialsManager = CredentialsManager(authentication: authentication,
                                                        storage: storage)
            }

            it("custom keychain should successfully set and clear credentials") {
                _ = credentialsManager.store(credentials: credentials)
                expect { try storage.data(forKey: "credentials") }.toNot(beNil())
                _ = credentialsManager.clear()
                expect { try storage.data(forKey: "credentials") }.to(throwError(SimpleKeychainError.itemNotFound))
            }
        }

        describe("clearing and revoking refresh token") {

            beforeEach {
                _ = credentialsManager.store(credentials: credentials)
                NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken])}, response: revokeTokenResponse())
            }

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should clear credentials under the default key and revoke the refresh token") {
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(beSuccessful())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }

            it("should not return an error when there are no credentials stored") {
                _ = credentialsManager.clear()
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(beSuccessful())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should not return an error when there is no refresh token, and clear credentials anyway") {
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
            
            it("should return the failure when the token could not be revoked, and not clear credentials") {
                let cause = AuthenticationError(description: "Revoke failed", statusCode: 400)
                let expectedError = CredentialsManagerError(code: .revokeFailed, cause: cause)
                NetworkStub.clearStubs()
                NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken])}, response: authFailure(code: "400", description: "Revoke failed"))
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(haveCredentialsManagerError(expectedError))
                        expect(credentialsManager.hasValid()).to(beTrue())
                        done()
                    }
                }
            }
            
            it("should include custom headers") {
                let key = "foo"
                let value = "bar"
                NetworkStub.addStub(condition: { $0.hasHeader(key, value: value)}, response: revokeTokenResponse())
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke(headers: [key: value], { result in
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
            
            it("should share a space in the keychain when using the same store key") {
                
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

            it("should have valid credentials when stored under the default key and not expired") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }

            it("should not have valid credentials when keychain is empty") {
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
                expect(credentialsManager.willExpire(credentials.expiresIn, within: ValidTTL)).to(beFalse())
            }

            it("should expire soon when the min ttl is greater than the at expiry") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.willExpire(credentials.expiresIn, within: InvalidTTL)).to(beTrue())
            }

            it("should not be expired when expiry of at is + 1 hour") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.hasExpired(credentials.expiresIn)).to(beFalse())
            }

            it("should be expired when expiry of at is - 1 hour") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                expect(credentialsManager.hasExpired(credentials.expiresIn)).to(beTrue())
            }

        }

        describe("renewability") {

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should have renewable credentials when stored under the default key and have a refresh token") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.canRenew()).to(beTrue())
            }

            it("should not have renewable credentials when keychain is empty") {
                expect(credentialsManager.canRenew()).to(beFalse())
            }

            it("should not have renewable credentials without a refresh token") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil)
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.canRenew()).to(beFalse())
            }

        }

        describe("scope") {

            it("should return true when the scope has changed") {
                let credentials = Credentials(scope: "openid email profile")
                expect(credentialsManager.hasScopeChanged(from: "openid email", to: credentials.scope)).to(beTrue())
            }

            it("should return false when the scope has not changed") {
                let credentials = Credentials(scope: "openid email")
                expect(credentialsManager.hasScopeChanged(from: "openid email", to: credentials.scope)).to(beFalse())
                expect(credentialsManager.hasScopeChanged(from: "email openid", to: credentials.scope)).to(beFalse())
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

        describe("retrieval of credentials") {

            beforeEach {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: nil, expiresIn: ExpiresIn * 2))
            }

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should error when there are no credentials stored") {
                _ = credentialsManager.clear()

                waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noCredentials)))
                        done()
                    }
                }
            }

            it("should error when there is no refresh token") {
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

            #if os(iOS) || os(visionOS)
            context("require biometrics") {

                it("should error when biometrics are unavailable") {
                    let expectedError = CredentialsManagerError(code: .biometricsFailed, cause: LAError(.biometryNotAvailable))
                    credentialsManager.enableBiometrics(withTitle: "Auth Title", cancelTitle: "Cancel Title", fallbackTitle: "Fallback Title")
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: .seconds(5)) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

                it("should error when biometric validation fails") {
                    let laContext = MockLAContext()
                    let bioAuth = BioAuthentication(authContext: laContext, evaluationPolicy: .deviceOwnerAuthenticationWithBiometrics, title: "Auth Title")
                    let cause = LAError(.appCancel)
                    let expectedError = CredentialsManagerError(code: .biometricsFailed, cause: cause)
                    laContext.replyError = cause
                    credentialsManager.bioAuth = bioAuth
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

                it("should yield new credentials when biometric validation succeeds") {
                    let laContext = MockLAContext()
                    let bioAuth = BioAuthentication(authContext: laContext, evaluationPolicy: .deviceOwnerAuthenticationWithBiometrics, title: "Biometric Auth")
                    credentialsManager.bioAuth = bioAuth
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, RefreshToken))
                            done()
                        }
                    }
                }

            }
            #endif

            context("renewal of credentials") {

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
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
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
                    let store = SimpleKeychain()
                    credentialsManager = CredentialsManager(authentication: authentication, storage: store)
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beSuccessful())
                            let storedCredentials = fetchCredentials(from: store)
                            expect(storedCredentials?.accessToken) == NewAccessToken
                            expect(storedCredentials?.idToken) == NewIdToken
                            expect(storedCredentials?.refreshToken) == RefreshToken
                            done()
                        }
                    }
                }

                it("should yield error on failed renewal") {
                    NetworkStub.clearStubs()
                    let cause = AuthenticationError(info: ["error": "invalid_request", "error_description": "missing_params"])
                    let expectedError = CredentialsManagerError(code: .renewFailed, cause: cause)
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authFailure(code: "invalid_request", description: "missing_params"))
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

                it("should yield error on failed store") {
                    class MockStore: CredentialsStorage {
                        func getEntry(forKey: String) -> Data? {
                            let credentials = Credentials(refreshToken: RefreshToken)
                            let data = try? NSKeyedArchiver.archivedData(withRootObject: credentials,
                                                                         requiringSecureCoding: true)
                            return data
                        }
                        func setEntry(_ data: Data, forKey: String) -> Bool {
                            return false
                        }
                        func deleteEntry(forKey: String) -> Bool {
                            return true
                        }
                    }

                    credentialsManager = CredentialsManager(authentication: authentication, storage: MockStore())
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(.storeFailed))
                            done()
                        }
                    }
                }

                it("renewal request should include custom parameters") {
                    let someId = UUID().uuidString
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "some_id": someId]) }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(parameters: ["some_id": someId]) { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            done()
                        }
                    }
                }

                it("renewal request should include custom headers") {
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasHeader(key, value: value) }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(headers: [key: value]) { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
            }

            context("forced renewal of credentials") {

                beforeEach {
                    _ = credentialsManager.store(credentials: credentials)
                }

                it("should not yield new credentials by default") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }

                it("should not yield new credentials without a new scope") {
                    credentials = Credentials(accessToken: AccessToken, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil) { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }

                it("should not yield new credentials with the same scope") {
                    credentials = Credentials(accessToken: AccessToken,  idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile") { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }

                it("should yield new credentials with a new scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile offline_access") { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken))
                            done()
                        }
                    }
                }

                it("should not yield new credentials with a min ttl less than its expiry") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(minTTL: ValidTTL) { result in
                            expect(result).to(haveCredentials(AccessToken, IdToken))
                            done()
                        }
                    }
                }

                it("should yield new credentials with a min ttl greater than its expiry") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(minTTL: InvalidTTL) { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken))
                            done()
                        }
                    }
                }

                it("should fail to yield new credentials with a min ttl greater than its expiry") {
                    NetworkStub.clearStubs()
                    let minTTL = 100_000
                    // The dates are not mocked, so they won't match exactly
                    let expectedError = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: Int(ExpiresIn - 1)))
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(minTTL: minTTL) { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

            }

            context("serial renewal of credentials from same thread") {

                it("should yield the stored credentials after the previous renewal operation succeeded") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])
                    }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))

                    credentials = Credentials(refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))

                            NetworkStub.clearStubs()
                        }
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            done()
                        }
                    }
                }

                it("should renew the credentials after the previous renewal operation failed") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])
                    }, response: apiFailureResponse())

                    credentials = Credentials(refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beUnsuccessful())

                            NetworkStub.clearStubs()
                            NetworkStub.addStub(condition: {
                                $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "request": "second"])
                            }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                        }
                        credentialsManager.credentials(parameters: ["request": "second"]) { result in
                            expect(result).to(haveCredentials())
                            done()
                        }
                    }
                }

            }

            context("serial renewal of credentials from different threads") {

                it("should yield the stored credentials after the previous renewal operation succeeded") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "request": "first"])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))

                    credentials = Credentials(refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        DispatchQueue.global(qos: .userInitiated).sync {
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
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])
                    }, response: apiFailureResponse())

                    credentials = Credentials(refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        DispatchQueue.global(qos: .userInitiated).sync {
                            credentialsManager.credentials { result in
                                expect(result).to(beUnsuccessful())

                                NetworkStub.clearStubs()
                                NetworkStub.addStub(condition: {
                                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "request": "second"])
                                }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                            }
                        }

                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager.credentials(parameters: ["request": "second"]) { result in
                                expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                                done()
                            }
                        }
                    }
                }
            }

        }

        describe("retrieval of api credentials") {
            
            beforeEach {
                NetworkStub.addStub(condition: {
                    $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
            }
            
            afterEach {
                _ = credentialsManager.clear()
                _ = credentialsManager.clear(forAudience: Audience)
            }
            
            it("should error when there are no credentials stored") {
                _ = credentialsManager.clear()
                _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.apiCredentials(forAudience: Audience) { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noCredentials)))
                        done()
                    }
                }
            }
            
            it("should error when there is no refresh token") {
                credentials = Credentials(refreshToken: nil,
                                          expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)
                _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.apiCredentials(forAudience: Audience) { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noRefreshToken)))
                        done()
                    }
                }
            }
            
            it("should return original api credentials as not expired") {
                apiCredentials = APICredentials(accessToken: AccessToken,
                                                tokenType: TokenType,
                                                expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.apiCredentials(forAudience: Audience) { result in
                        expect(result).to(haveAPICredentials())
                        done()
                    }
                }
            }
            
            context("renewal of api credentials") {
                
                it("should exchange refresh token for new api credentials") {
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveAPICredentials(NewAccessToken))
                            done()
                        }
                    }
                }
                
                it("should store new api credentials") {
                    let store = SimpleKeychain()
                    credentialsManager = CredentialsManager(authentication: authentication, storage: store)
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(beSuccessful())
                            let storedCredentials = fetchAPICredentials(from: store)
                            expect(storedCredentials?.accessToken) == NewAccessToken
                            done()
                        }
                    }
                }
                
                it("should update existing api credentials without refresh token rotation") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: authResponse(accessToken: NewAccessToken,
                                              tokenType: NewTokenType,
                                              idToken: NewIdToken,
                                              refreshToken: nil,
                                              expiresIn: ExpiresIn,
                                              scope: NewScope))
                    
                    let store = SimpleKeychain()
                    credentialsManager = CredentialsManager(authentication: authentication, storage: store)
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveAPICredentials(NewAccessToken, NewTokenType, NewScope))
                            let storedCredentials = fetchCredentials(from: store)
                            expect(storedCredentials?.accessToken) == AccessToken
                            expect(storedCredentials?.tokenType) == TokenType
                            expect(storedCredentials?.idToken) == NewIdToken // Gets updated
                            expect(storedCredentials?.refreshToken) == RefreshToken // Does not get updated
                            expect(storedCredentials?.scope) == Scope
                            done()
                        }
                    }
                }
                
                it("should update existing api credentials with refresh token rotation") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: authResponse(accessToken: NewAccessToken,
                                              tokenType: NewTokenType,
                                              idToken: NewIdToken,
                                              refreshToken: NewRefreshToken,
                                              expiresIn: ExpiresIn,
                                              scope: NewScope))
                    
                    let store = SimpleKeychain()
                    credentialsManager = CredentialsManager(authentication: authentication, storage: store)
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveAPICredentials(NewAccessToken, NewTokenType, NewScope))
                            let storedCredentials = fetchCredentials(from: store)
                            expect(storedCredentials?.accessToken) == AccessToken
                            expect(storedCredentials?.tokenType) == TokenType
                            expect(storedCredentials?.idToken) == NewIdToken // Gets updated
                            expect(storedCredentials?.refreshToken) == NewRefreshToken // Gets updated
                            expect(storedCredentials?.scope) == Scope
                            done()
                        }
                    }
                }
                
                it("should yield error on failed renewal") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: authFailure(code: "invalid_request", description: "missing_params"))
                    
                    let cause = AuthenticationError(info: ["error": "invalid_request", "error_description": "missing_params"])
                    let expectedError = CredentialsManagerError(code: .apiExchangeFailed, cause: cause)
                    
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }
                
                it("should yield error on failed store") {
                    class MockStore: CredentialsStorage {
                        func getEntry(forKey key: String) -> Data? {
                            if key == Audience {
                                let apiCredentials = APICredentials(accessToken: AccessToken,
                                                                    tokenType: TokenType,
                                                                    expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                                return try? JSONEncoder().encode(apiCredentials)
                            }
                            
                            let credentials = Credentials(refreshToken: RefreshToken)
                            return try? NSKeyedArchiver.archivedData(withRootObject: credentials,
                                                                     requiringSecureCoding: true)
                        }
                        func setEntry(_ data: Data, forKey: String) -> Bool {
                            return false
                        }
                        func deleteEntry(forKey: String) -> Bool {
                            return true
                        }
                    }
                    
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    credentialsManager = CredentialsManager(authentication: authentication, storage: MockStore())
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveCredentialsManagerError(.storeFailed))
                            done()
                        }
                    }
                }
                
                it("renewal request should include custom parameters") {
                    let key = "foo"
                    let value = "bar"

                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience, key: value])
                    }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
                    
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience, parameters: [key: value]) { result in
                            expect(result).to(haveAPICredentials(NewAccessToken))
                            done()
                        }
                    }
                }
                
                it("renewal request should include custom headers") {
                    let key = "foo"
                    let value = "bar"

                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasHeader(key, value: value)
                    }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
                    
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience, headers: [key: value]) { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
            }

            context("forced renewal of api credentials") {

                beforeEach {
                    apiCredentials = APICredentials(accessToken: AccessToken,
                                                    tokenType: TokenType,
                                                    expiresIn: Date(timeIntervalSinceNow: ExpiresIn),
                                                    scope: Scope)
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                }

                it("should not yield new api credentials by default") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveAPICredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should not yield new api credentials with the same scope") {
                    apiCredentials = APICredentials(accessToken: AccessToken,
                                                    tokenType: TokenType,
                                                    expiresIn: Date(timeIntervalSinceNow: ExpiresIn),
                                                    scope: "openid phone")
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience, scope: "openid phone") { result in
                            expect(result).to(haveAPICredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should yield new api credentials with a new scope") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience, "scope": "openid email"])
                    }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
                    apiCredentials = APICredentials(accessToken: AccessToken,
                                                    tokenType: TokenType,
                                                    expiresIn: Date(timeIntervalSinceNow: ExpiresIn),
                                                    scope: "openid phone")
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience, scope: "openid email") { result in
                            expect(result).to(haveAPICredentials(NewAccessToken))
                            done()
                        }
                    }
                }

                it("should not yield new api credentials with a min ttl less than its expiry") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience, minTTL: ValidTTL) { result in
                            expect(result).to(haveAPICredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should yield new api credentials with a min ttl greater than its expiry") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn * 2))
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience, minTTL: InvalidTTL) { result in
                            expect(result).to(haveAPICredentials(NewAccessToken))
                            done()
                        }
                    }
                }

                it("should fail to yield new api credentials with a min ttl greater than its expiry") {
                    let minTTL = 100_000
                    // The dates are not mocked, so they won't match exactly
                    let expectedError = CredentialsManagerError(code: .largeMinTTL(minTTL: minTTL, lifetime: Int(ExpiresIn - 1)))
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience, minTTL: minTTL) { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

            }

            context("serial renewal of api credentials from same thread") {
                
                it("should yield the stored api credentials after the previous renewal operation succeeded") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
                    
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveAPICredentials(NewAccessToken))
                            
                            NetworkStub.clearStubs()
                        }
                        
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(haveAPICredentials(NewAccessToken))
                            done()
                        }
                    }
                }
                
                it("should exchange the api credentials after the previous renewal operation failed") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: apiFailureResponse())

                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.apiCredentials(forAudience: Audience) { result in
                            expect(result).to(beUnsuccessful())

                            NetworkStub.clearStubs()
                            NetworkStub.addStub(condition: {
                                $0.isToken(Domain) &&
                                $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience, "request": "second"])
                            }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
                        }
                        credentialsManager.apiCredentials(forAudience: Audience, parameters: ["request": "second"]) { result in
                            expect(result).to(haveAPICredentials())
                            done()
                        }
                    }
                }
                
            }
            
            context("serial renewal of api credentials from different threads") {
                
                it("should yield the stored api credentials after the previous renewal operation succeeded") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience, "request": "first"])
                    }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
                    
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    
                    waitUntil(timeout: Timeout) { done in
                        DispatchQueue.global(qos: .userInitiated).sync {
                            credentialsManager.apiCredentials(forAudience: Audience,
                                                              parameters: ["request": "first"]) { result in
                                expect(result).to(haveAPICredentials(NewAccessToken))
                            }
                        }
                        
                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager.apiCredentials(forAudience: Audience) { result in
                                expect(result).to(haveAPICredentials(NewAccessToken))
                                done()
                            }
                        }
                    }
                }

                it("should renew the api credentials after the previous renewal operation failed") {
                    NetworkStub.clearStubs()
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: apiFailureResponse())

                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)

                    waitUntil(timeout: Timeout) { done in
                        DispatchQueue.global(qos: .userInitiated).sync {
                            credentialsManager.apiCredentials(forAudience: Audience) { result in
                                expect(result).to(beUnsuccessful())

                                NetworkStub.clearStubs()
                                NetworkStub.addStub(condition: {
                                    $0.isToken(Domain) &&
                                    $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience, "request": "second"])
                                }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: ExpiresIn))
                            }
                        }

                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager.apiCredentials(forAudience: Audience,
                                                              parameters: ["request": "second"]) { result in
                                expect(result).to(haveAPICredentials(NewAccessToken))
                                done()
                            }
                        }
                    }
                }
            }

        }

        describe("renew") {

            beforeEach {
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2))
            }

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should error when there are no credentials stored") {
                _ = credentialsManager.clear()

                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noCredentials)))
                        done()
                    }
                }
            }

            it("should error when there is no refresh token") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil)
                _ = credentialsManager.store(credentials: credentials)

                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noRefreshToken)))
                        done()
                    }
                }
            }

            it("should yield new credentials without refresh token rotation") {
                NetworkStub.clearStubs()
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: nil, expiresIn: ExpiresIn * 2))
                _ = credentialsManager.store(credentials: credentials)
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentials(NewAccessToken, NewIdToken, RefreshToken))
                        done()
                    }
                }
            }

            it("should yield new credentials with refresh token rotation") {
                _ = credentialsManager.store(credentials: credentials)
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                        done()
                    }
                }
            }

            it("should store new credentials under the default key") {
                let store = SimpleKeychain()
                credentialsManager = CredentialsManager(authentication: authentication, storage: store)
                _ = credentialsManager.store(credentials: credentials)
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(beSuccessful())
                        let storedCredentials = fetchCredentials(from: store)
                        expect(storedCredentials?.accessToken) == NewAccessToken
                        expect(storedCredentials?.idToken) == NewIdToken
                        expect(storedCredentials?.refreshToken) == NewRefreshToken
                        done()
                    }
                }
            }

            it("should yield error on failed renewal") {
                NetworkStub.clearStubs()
                let cause = AuthenticationError(info: ["error": "invalid_request", "error_description": "missing_params"])
                let expectedError = CredentialsManagerError(code: .renewFailed, cause: cause)
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authFailure(code: "invalid_request", description: "missing_params"))
                _ = credentialsManager.store(credentials: credentials)
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(expectedError))
                        done()
                    }
                }
            }

            it("should yield error on failed store") {
                class MockStore: CredentialsStorage {
                    func getEntry(forKey: String) -> Data? {
                        let credentials = Credentials(refreshToken: RefreshToken)
                        return try? NSKeyedArchiver.archivedData(withRootObject: credentials,
                                                                 requiringSecureCoding: true)
                    }
                    func setEntry(_ data: Data, forKey: String) -> Bool {
                        return false
                    }
                    func deleteEntry(forKey: String) -> Bool {
                        return true
                    }
                }

                credentialsManager = CredentialsManager(authentication: authentication, storage: MockStore())
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(.storeFailed))
                        done()
                    }
                }
            }

            it("renewal request should include custom parameters") {
                let someId = UUID().uuidString
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "some_id": someId]) }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew(parameters: ["some_id": someId]) { result in
                        expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                        done()
                    }
                }
            }

            it("renewal request should include custom headers") {
                let key = "foo"
                let value = "bar"
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasHeader(key, value: value) }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)
                waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew(headers: [key: value]) { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            context("concurrency") {
                let newAccessToken1 = "new-access-token-1"
                let newIDToken1 = "new-id-token-1"
                let newRefreshToken1 = "new-refresh-token-1"
                let newAccessToken2 = "new-access-token-2"
                let newIDToken2 = "new-id-token-2"
                let newRefreshToken2 = "new-refresh-token-2"
                
                beforeEach {
                    NetworkStub.clearStubs()
                }

                it("should renew the credentials serially from the same thread") {
                    _ = credentialsManager.store(credentials: credentials)

                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "request": "first"])}, response: authResponse(accessToken: newAccessToken1, idToken: newIDToken1, refreshToken: newRefreshToken1, expiresIn: ExpiresIn))

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.renew(parameters: ["request": "first"]) { result in
                            expect(result).to(haveCredentials(newAccessToken1, newIDToken1, newRefreshToken1))
                            NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": newRefreshToken1, "request": "second"])}, response: authResponse(accessToken: newAccessToken2, idToken: newIDToken2, refreshToken: newRefreshToken2, expiresIn: ExpiresIn))
                        }
                        credentialsManager.renew(parameters: ["request": "second"]) { result in
                            expect(result).to(haveCredentials(newAccessToken2, newIDToken2, newRefreshToken2))
                            done()
                        }
                    }
                }

                it("should renew the credentials serially from different threads") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "request": "first"])}, response: authResponse(accessToken: newAccessToken1, idToken: newIDToken1, refreshToken: newRefreshToken1, expiresIn: ExpiresIn))
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": newRefreshToken1, "request": "second"])}, response: authResponse(accessToken: newAccessToken2, idToken: newIDToken2, refreshToken: newRefreshToken2, expiresIn: ExpiresIn))

                    _ = credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        DispatchQueue.global(qos: .userInitiated).sync {
                            credentialsManager.renew(parameters: ["request": "first"]) { result in
                                expect(result).to(haveCredentials(newAccessToken1, newIDToken1, newRefreshToken1))
                            }
                        }

                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager.renew(parameters: ["request": "second"]) { result in
                                expect(result).to(haveCredentials(newAccessToken2, newIDToken2, newRefreshToken2))
                                done()
                            }
                        }
                    }
                }

            }

        }

        describe("combine") {
            var cancellables: Set<AnyCancellable> = []

            afterEach {
                _ = credentialsManager.clear()
                _ = credentialsManager.clear(forAudience: Audience)
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
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, key: value]) && $0.hasHeader(key, value: value)}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .credentials(withScope: "openid profile offline_access",
                                         minTTL: ValidTTL,
                                         parameters: [key: value],
                                         headers: [key: value])
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

            context("api credentials") {

                it("should emit only one value") {
                    apiCredentials = APICredentials(accessToken: AccessToken,
                                                    tokenType: TokenType,
                                                    expiresIn: Date(timeIntervalSinceNow: ExpiresIn), // Will return the stored api credentials
                                                    scope: Scope)
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .apiCredentials(forAudience: Audience)
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
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: authResponse(accessToken: NewAccessToken,
                                              idToken: NewIdToken,
                                              refreshToken: NewRefreshToken,
                                              expiresIn: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .apiCredentials(forAudience: Audience)
                            .sink(receiveCompletion: { completion in
                                guard case .finished = completion else { return }
                                done()
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    }
                }

                it("should complete using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience, "scope": Scope, key: value]) &&
                        $0.hasHeader(key, value: value)
                    }, response: authResponse(accessToken: NewAccessToken,
                                              idToken: NewIdToken,
                                              refreshToken: NewRefreshToken,
                                              expiresIn: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .apiCredentials(forAudience: Audience,
                                            scope: Scope,
                                            minTTL: ValidTTL,
                                            parameters: [key: value],
                                            headers: [key: value])
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
                            .apiCredentials(forAudience: Audience)
                            .ignoreOutput()
                            .sink(receiveCompletion: { completion in
                                guard case .failure = completion else { return }
                                done()
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    }
                }

            }

            context("renew") {

                beforeEach {
                    _ = credentialsManager.store(credentials: credentials)
                }

                it("should emit only one value") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2))
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .renew()
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
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2))
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .renew()
                            .sink(receiveCompletion: { completion in
                                guard case .finished = completion else { return }
                                done()
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    }
                }

                it("should complete using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, key: value]) && $0.hasHeader(key, value: value)}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .renew(parameters: [key: value], headers: [key: value])
                            .sink(receiveCompletion: { completion in
                                guard case .finished = completion else { return }
                                done()
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    }
                }

                it("should complete with an error") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authFailure(code: "invalid_request", description: "missing_params"))
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .renew()
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
                    NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken])}, response: revokeTokenResponse())
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
                    NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken])}, response: revokeTokenResponse())
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
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken]) && $0.hasHeader(key, value: value)}, response: revokeTokenResponse())
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager
                            .revoke(headers: [key: value])
                            .sink(receiveCompletion: { completion in
                                guard case .finished = completion else { return }
                                done()
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    }
                }

                it("should complete with an error") {
                    NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken])}, response: apiFailureResponse())
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

        #if canImport(_Concurrency)
        describe("async await") {

            afterEach {
                _ = credentialsManager.clear()
                _ = credentialsManager.clear(forAudience: Audience)
            }

            context("credentials") {

                it("should return the credentials using the default parameter values") {
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.credentials()
                            done()
                        }
                    }
                }

                it("should return the credentials using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, key: value]) && $0.hasHeader(key, value: value)}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.credentials(withScope: "openid profile offline_access",
                                                                         minTTL: ValidTTL,
                                                                         parameters: [key: value],
                                                                         headers: [key: value])
                            done()
                        }
                    }
                }

                it("should throw an error") {
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            do {
                                _ = try await credentialsManager.credentials()
                            } catch {
                                done()
                            }
                        }
                    }
                }

            }

            context("api credentials") {

                it("should return the credentials using the default parameter values") {
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) && 
                        $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience])
                    }, response: authResponse(accessToken: NewAccessToken,
                                              idToken: NewIdToken,
                                              refreshToken: NewRefreshToken,
                                              expiresIn: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.apiCredentials(forAudience: Audience)
                            done()
                        }
                    }
                }

                it("should return the credentials using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: {
                        $0.isToken(Domain) &&
                        $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience, "scope": Scope, key: value]) &&
                        $0.hasHeader(key, value: value)
                    }, response: authResponse(accessToken: NewAccessToken,
                                              idToken: NewIdToken,
                                              refreshToken: NewRefreshToken,
                                              expiresIn: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    _ = credentialsManager.store(apiCredentials: apiCredentials, forAudience: Audience)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.apiCredentials(forAudience: Audience,
                                                                            scope: Scope,
                                                                            minTTL: ValidTTL,
                                                                            parameters: [key: value],
                                                                            headers: [key: value])
                            done()
                        }
                    }
                }

                it("should throw an error") {
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            do {
                                _ = try await credentialsManager.apiCredentials(forAudience: Audience)
                            } catch {
                                done()
                            }
                        }
                    }
                }

            }

            context("renew") {

                beforeEach {
                    _ = credentialsManager.store(credentials: credentials)
                }

                it("should renew the credentials using the default parameter values") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2))
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            let newCredentials = try await credentialsManager.renew()
                            expect(newCredentials.accessToken) == NewAccessToken
                            expect(newCredentials.idToken) == NewIdToken
                            expect(newCredentials.refreshToken) == NewRefreshToken
                            done()
                        }
                    }
                }

                it("should renew the credentials using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, key: value]) && $0.hasHeader(key, value: value)}, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            let newCredentials = try await credentialsManager.renew(parameters: [key: value],
                                                                                    headers: [key: value])
                            expect(newCredentials.accessToken) == NewAccessToken
                            expect(newCredentials.idToken) == NewIdToken
                            expect(newCredentials.refreshToken) == NewRefreshToken
                            done()
                        }
                    }
                }

                it("should throw an error") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken])}, response: authFailure(code: "invalid_request", description: "missing_params"))
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            do {
                                _ = try await credentialsManager.renew()
                            } catch {
                                done()
                            }
                        }
                    }
                }

            }

            context("revoke") {

                it("should revoke using the default parameter values") {
                    NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken])}, response: revokeTokenResponse())
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.revoke()
                            done()
                        }
                    }
                }

                it("should revoke using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken]) && $0.hasHeader(key, value: value)}, response: revokeTokenResponse())
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.revoke(headers: [key: value])
                            done()
                        }
                    }
                }

                it("should throw an error") {
                    NetworkStub.addStub(condition: { $0.isRevokeToken(Domain) && $0.hasAtLeast(["token": RefreshToken])}, response: apiFailureResponse())
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: Timeout) { done in
                        Task.init {
                            do {
                                _ = try await credentialsManager.revoke()
                            } catch {
                                done()
                            }
                        }
                    }
                }

            }

        }
        #endif

    }
}

// MARK: - Private Functions

private func fetchCredentials(from store: CredentialsStorage) -> Credentials? {
    guard let data = store.getEntry(forKey: "credentials") else { return nil }
    return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data)
}

private func fetchAPICredentials(forAudience audience: String = Audience, from store: CredentialsStorage) -> APICredentials? {
    guard let data = store.getEntry(forKey: audience) else { return nil }
    return try? JSONDecoder().decode(APICredentials.self, from: data)
}
