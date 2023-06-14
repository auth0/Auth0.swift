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
private let Timeout: NimbleTimeInterval = .seconds(2)
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
                
                stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in return revokeTokenResponse() }.name = "revoke success"
            }
            
            afterEach {
                _ = credentialsManager.clear()
            }
            
            it("should clear credentials and revoke the refresh token") {
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.revoke { result in
                        expect(result).to(beSuccessful())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should not return an error if there were no credentials stored") {
                _ = credentialsManager.clear()
                
                await waitUntil(timeout: Timeout) { done in
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
                
                await waitUntil(timeout: Timeout) { done in
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
                await waitUntil(timeout: Timeout) { done in
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
                stub(condition: hasHeader(key, value: value)) { _ in return revokeTokenResponse() }.name = "revoke success"
                await waitUntil(timeout: Timeout) { done in
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
                                
                await waitUntil(timeout: .seconds(200)) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken, RefreshToken))
                        done()
                    }
                }
                
                await waitUntil(timeout: Timeout) { done in
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
                
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentials(AccessToken, IdToken, RefreshToken))
                        done()
                    }
                }

                await waitUntil(timeout: Timeout) { done in
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

        describe("renewability") {

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should have renewable credentials when stored and have a refresh token") {
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
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                    return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: nil, expiresIn: ExpiresIn * 2)
                }.name = "renewal succeeded"
            }

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should error when no credentials stored") {
                _ = credentialsManager.clear()

                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noCredentials)))
                        done()
                    }
                }
            }

            it("should error when no refresh token") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)

                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noRefreshToken)))
                        done()
                    }
                }
            }

            it("should return original credentials as not expired") {
                _ = credentialsManager.store(credentials: credentials)

                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.credentials { result in
                        expect(result).to(haveCredentials())
                        done()
                    }
                }
            }

            #if os(iOS)
            context("require biometrics") {

                it("should error when biometrics are unavailable") {
                    let expectedError = CredentialsManagerError(code: .biometricsFailed, cause: LAError(.biometryNotAvailable))
                    credentialsManager.enableBiometrics(withTitle: "Auth Title", cancelTitle: "Cancel Title", fallbackTitle: "Fallback Title")
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)

                    await waitUntil(timeout: Timeout) { done in
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

                    await waitUntil(timeout: Timeout) { done in
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

                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, RefreshToken))
                            done()
                        }
                    }
                }

            }
            #endif

            context("renewal") {

                it("should yield new credentials without refresh token rotation") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
                    await waitUntil(timeout: Timeout) { done in
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
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beSuccessful())
                            let storedCredentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: store.data(forKey: "credentials"))
                            expect(storedCredentials?.accessToken) == NewAccessToken
                            expect(storedCredentials?.idToken) == NewIdToken
                            expect(storedCredentials?.refreshToken) == RefreshToken
                            done()
                        }
                    }
                }

                it("should yield error on failed renewal") {
                    let cause = AuthenticationError(info: ["error": "invalid_request", "error_description": "missing_params"])
                    let expectedError = CredentialsManagerError(code: .renewFailed, cause: cause)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authFailure(code: "invalid_request", description: "missing_params")
                    }.name = "renewal failed"
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

                it("should yield error on failed store") {
                    class MockStore: CredentialsStorage {
                        func getEntry(forKey: String) -> Data? {
                            let credentials = Credentials(accessToken: AccessToken,
                                                          tokenType: TokenType,
                                                          idToken: IdToken,
                                                          refreshToken: RefreshToken,
                                                          expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
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
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(.storeFailed))
                            done()
                        }
                    }
                }

                it("renewal request should include custom parameters") {
                    let someId = UUID().uuidString
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "some_id": someId])) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(parameters: ["some_id": someId]) { result in
                            expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            done()
                        }
                    }
                }

                it("renewal request should include custom headers") {
                    let key = "foo"
                    let value = "bar"
                    stub(condition: hasHeader(key, value: value)) {
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(headers: [key: value]) { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }
                }
            }

            context("forced renewal") {

                beforeEach {
                    _ = credentialsManager.store(credentials: credentials)
                }

                it("should not yield a new access token by default") {
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should not yield a new access token without a new scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil) { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should not yield a new access token with the same scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile") { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should yield a new access token with a new scope") {
                    credentials = Credentials(accessToken: AccessToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn), scope: "openid profile")
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: "openid profile offline_access") { result in
                            expect(result).to(haveCredentials(NewAccessToken))
                            done()
                        }
                    }
                }

                it("should not yield a new access token with a min ttl less than its expiry") {
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(minTTL: ValidTTL) { result in
                            expect(result).to(haveCredentials(AccessToken))
                            done()
                        }
                    }
                }

                it("should yield a new access token with a min ttl greater than its expiry") {
                    await waitUntil(timeout: Timeout) { done in
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
                        _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials(withScope: nil, minTTL: minTTL) { result in
                            expect(result).to(haveCredentialsManagerError(expectedError))
                            done()
                        }
                    }
                }

            }

            context("serial renewal from same thread") {

                it("should yield the stored credentials after the previous renewal operation succeeded") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    await waitUntil(timeout: Timeout) { done in
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
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beUnsuccessful())
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

            context("serial renewal from different threads") {

                it("should yield the stored credentials after the previous renewal operation succeeded") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "request": "first"])) { request in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    await waitUntil(timeout: Timeout) { [credentialsManager] done in
                        DispatchQueue.global(qos: .utility).sync {
                            credentialsManager?.credentials(parameters: ["request": "first"]) { result in
                                expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                            }
                        }
                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager?.credentials { result in
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
                    await waitUntil(timeout: Timeout) { [credentialsManager] done in
                        DispatchQueue.global(qos: .utility).sync {
                            credentialsManager?.credentials(parameters: ["request": "first"]) { result in
                                expect(result).to(beUnsuccessful())
                            }
                        }
                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager?.credentials(parameters: ["request": "second"]) { result in
                                expect(result).to(haveCredentials())
                                done()
                            }
                        }
                    }
                }
            }

        }

        describe("renew") {

            beforeEach {
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                    return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2)
                }.name = "renewal succeeded"
            }

            afterEach {
                _ = credentialsManager.clear()
            }

            it("should error when no credentials stored") {
                _ = credentialsManager.clear()

                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noCredentials)))
                        done()
                    }
                }
            }

            it("should error when no refresh token") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil)
                _ = credentialsManager.store(credentials: credentials)

                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(CredentialsManagerError(code: .noRefreshToken)))
                        done()
                    }
                }
            }

            it("should yield new credentials without refresh token rotation") {
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                    return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: nil, expiresIn: ExpiresIn * 2)
                }.name = "renewal succeeded"
                _ = credentialsManager.store(credentials: credentials)
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentials(NewAccessToken, NewIdToken, RefreshToken))
                        done()
                    }
                }
            }

            it("should yield new credentials with refresh token rotation") {
                _ = credentialsManager.store(credentials: credentials)
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                        done()
                    }
                }
            }

            it("should store new credentials") {
                let store = SimpleKeychain()
                credentialsManager = CredentialsManager(authentication: authentication, storage: store)
                _ = credentialsManager.store(credentials: credentials)
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(beSuccessful())
                        let storedCredentials = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: store.data(forKey: "credentials"))
                        expect(storedCredentials?.accessToken) == NewAccessToken
                        expect(storedCredentials?.idToken) == NewIdToken
                        expect(storedCredentials?.refreshToken) == NewRefreshToken
                        done()
                    }
                }
            }

            it("should yield error on failed renewal") {
                let cause = AuthenticationError(info: ["error": "invalid_request", "error_description": "missing_params"])
                let expectedError = CredentialsManagerError(code: .renewFailed, cause: cause)
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                    return authFailure(code: "invalid_request", description: "missing_params")
                }.name = "renewal failed"
                _ = credentialsManager.store(credentials: credentials)
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(expectedError))
                        done()
                    }
                }
            }

            it("should yield error on failed store") {
                class MockStore: CredentialsStorage {
                    func getEntry(forKey: String) -> Data? {
                        let credentials = Credentials(accessToken: AccessToken, idToken: IdToken, refreshToken: RefreshToken)
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
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew { result in
                        expect(result).to(haveCredentialsManagerError(.storeFailed))
                        done()
                    }
                }
            }

            it("renewal request should include custom parameters") {
                let someId = UUID().uuidString
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "some_id": someId])) {
                    _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                }
                _ = credentialsManager.store(credentials: credentials)
                await waitUntil(timeout: Timeout) { done in
                    credentialsManager.renew(parameters: ["some_id": someId]) { result in
                        expect(result).to(haveCredentials(NewAccessToken, NewIdToken, NewRefreshToken))
                        done()
                    }
                }
            }

            it("renewal request should include custom headers") {
                let key = "foo"
                let value = "bar"
                stub(condition: hasHeader(key, value: value)) {
                    _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                }
                _ = credentialsManager.store(credentials: credentials)
                await waitUntil(timeout: Timeout) { done in
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

                it("should renew the credentials serially from the same thread") {
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "request": "first"])) { request in
                        return authResponse(accessToken: newAccessToken1, idToken: newIDToken1, refreshToken: newRefreshToken1, expiresIn: ExpiresIn)
                    }
                    await waitUntil(timeout: Timeout) { done in
                        credentialsManager.renew(parameters: ["request": "first"]) { result in
                            expect(result).to(haveCredentials(newAccessToken1, newIDToken1, newRefreshToken1))
                            stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": newRefreshToken1, "request": "second"])) { request in
                                return authResponse(accessToken: newAccessToken2, idToken: newIDToken2, refreshToken: newRefreshToken2, expiresIn: ExpiresIn)
                            }
                        }
                        credentialsManager.renew(parameters: ["request": "second"]) { result in
                            expect(result).to(haveCredentials(newAccessToken2, newIDToken2, newRefreshToken2))
                            done()
                        }
                    }
                }

                it("should renew the credentials serially from different threads") {
                    _ = credentialsManager.store(credentials: credentials)
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, "request": "first"])) { request in
                        return authResponse(accessToken: newAccessToken1, idToken: newIDToken1, refreshToken: newRefreshToken1, expiresIn: ExpiresIn)
                    }
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": newRefreshToken1, "request": "second"])) { request in
                        return authResponse(accessToken: newAccessToken2, idToken: newIDToken2, refreshToken: newRefreshToken2, expiresIn: ExpiresIn)
                    }
                    await waitUntil(timeout: Timeout) { [credentialsManager] done in
                        DispatchQueue.global(qos: .utility).sync {
                            credentialsManager?.renew(parameters: ["request": "first"]) { result in
                                expect(result).to(haveCredentials(newAccessToken1, newIDToken1, newRefreshToken1))
                            }
                        }
                        DispatchQueue.global(qos: .background).sync {
                            credentialsManager?.renew(parameters: ["request": "second"]) { result in
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
                cancellables.removeAll()
            }

            context("credentials") {

                it("should emit only one value") {
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
                    await waitUntil(timeout: Timeout) { done in
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
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, key: value]) && hasHeader(key, value: value)) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
                    await waitUntil(timeout: Timeout) { done in
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

            context("renew") {

                beforeEach {
                    _ = credentialsManager.store(credentials: credentials)
                }

                it("should emit only one value") {
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2)
                    }.name = "renewal succeeded"
                    await waitUntil(timeout: Timeout) { done in
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
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2)
                    }.name = "renewal succeeded"
                    await waitUntil(timeout: Timeout) { done in
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
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, key: value]) && hasHeader(key, value: value)) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    await waitUntil(timeout: Timeout) { done in
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
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authFailure(code: "invalid_request", description: "missing_params")
                    }.name = "renewal failed"
                    await waitUntil(timeout: Timeout) { done in
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
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                        return revokeTokenResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
                    await waitUntil(timeout: Timeout) { done in
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
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken]) && hasHeader(key, value: value)) { _ in
                        return revokeTokenResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                        return apiFailureResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
            }

            context("credentials") {

                it("should return the credentials using the default parameter values") {
                    let credentialsManager = credentialsManager!
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.credentials()
                            done()
                        }
                    }
                }

                it("should return the credentials using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    let credentialsManager = credentialsManager!
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, key: value]) && hasHeader(key, value: "bar")) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
                    let credentialsManager = credentialsManager!
                    await waitUntil(timeout: Timeout) { done in
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

            context("renew") {

                beforeEach {
                    _ = credentialsManager.store(credentials: credentials)
                }

                it("should renew the credentials using the default parameter values") {
                    let credentialsManager = credentialsManager!
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn * 2)
                    }.name = "renewal succeeded"
                    await waitUntil(timeout: Timeout) { done in
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
                    let credentialsManager = credentialsManager!
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken, key: value]) && hasHeader(key, value: "bar")) { _ in
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresIn: ExpiresIn)
                    }
                    await waitUntil(timeout: Timeout) { done in
                        Task.init {
                            let newCredentials = try await credentialsManager.renew(parameters: [key: value], headers: [key: value])
                            expect(newCredentials.accessToken) == NewAccessToken
                            expect(newCredentials.idToken) == NewIdToken
                            expect(newCredentials.refreshToken) == NewRefreshToken
                            done()
                        }
                    }
                }

                it("should throw an error") {
                    let credentialsManager = credentialsManager!
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in
                        return authFailure(code: "invalid_request", description: "missing_params")
                    }.name = "renewal failed"
                    await waitUntil(timeout: Timeout) { done in
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
                    let credentialsManager = credentialsManager!
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                        return revokeTokenResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.revoke()
                            done()
                        }
                    }
                }

                it("should revoke using custom parameter values") {
                    let key = "foo"
                    let value = "bar"
                    let credentialsManager = credentialsManager!
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken]) && hasHeader(key, value: value)) { _ in
                        return revokeTokenResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
                        Task.init {
                            _ = try await credentialsManager.revoke(headers: [key: value])
                            done()
                        }
                    }
                }

                it("should throw an error") {
                    let credentialsManager = credentialsManager!
                    stub(condition: isRevokeToken(Domain) && hasAtLeast(["token": RefreshToken])) { _ in
                        return apiFailureResponse()
                    }
                    _ = credentialsManager.store(credentials: credentials)
                    await waitUntil(timeout: Timeout) { done in
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
