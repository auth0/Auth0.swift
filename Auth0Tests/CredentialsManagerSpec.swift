// CredentialsManagerSpec.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Quick
import Nimble
import OHHTTPStubs
import SimpleKeychain
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
                waitUntil(timeout: 2) { done in
                    credentialsManager.revoke {
                        expect($0).to(beNil())
                        expect(credentialsManager.hasValid()).to(beFalse())
                        done()
                    }
                }
            }
            
            it("should not return an error if there were no credentials stored") {
                _ = credentialsManager.clear()
                
                waitUntil(timeout: 2) { done in
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
                
                waitUntil(timeout: 2) { done in
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
                
                waitUntil(timeout: 2) { done in
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
                                
                waitUntil(timeout: 200) { done in
                    credentialsManager.credentials {
                        expect($0).to(beNil())
                        expect($1!.accessToken) == AccessToken
                        expect($1!.refreshToken) == RefreshToken
                        expect($1!.idToken) == IdToken
                        done()
                    }
                }
                
                waitUntil(timeout: 2) { done in
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
                
                waitUntil(timeout: 2) { done in
                    credentialsManager.credentials {
                        expect($0).to(beNil())
                        expect($1!.accessToken) == AccessToken
                        expect($1!.refreshToken) == RefreshToken
                        expect($1!.idToken) == IdToken
                        done()
                    }
                }

                waitUntil(timeout: 2) { done in
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

        describe("valididity") {

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

            it("should not have valid credentials when no access token") {
                let credentials = Credentials(accessToken: nil, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beFalse())
            }
        }
        
        describe("validity expiry") {
            
            afterEach {
                _ = credentialsManager.clear()
            }

            it("should not be expired when expiry of at is + 1 hour") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: nil, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.hasExpired(credentials)).to(beFalse())
            }
            
            it("should not be expired when expiry of at is +1 hour and idt not expired") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: ValidToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.hasExpired(credentials)).to(beFalse())
            }
            
            it("should be expired when expiry of at is - 1 hour") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: nil, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                expect(credentialsManager.hasExpired(credentials)).to(beTrue())
            }
            
            it("should be expired when expiry of at is + 1 hour and idt is expired") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: ExpiredToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.hasExpired(credentials)).to(beTrue())
            }
            
        }
        
        describe("validity with id token") {
            
            afterEach {
                _ = credentialsManager.clear()
            }

            it("should be valid when at valid and id token valid") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: ValidToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beTrue())
            }
            
            it("should not be valid when at valid and id token expired") {
                let credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: ExpiredToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: ExpiresIn))
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(credentialsManager.hasValid()).to(beFalse())
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

            it("should error when expiry not present") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: nil)
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

                    waitUntil(timeout: 2) { done in
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
                    waitUntil(timeout: 2) { done in
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
                    waitUntil(timeout: 2) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == NewAccessToken
                            expect(newCredentials?.refreshToken) == NewRefreshToken
                            expect(newCredentials?.idToken) == NewIdToken
                            done()
                        }
                    }
                }
                
                it("should yield new credentials when idToken expired") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: ExpiredToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: 10))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: 2) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == NewAccessToken
                            expect(newCredentials?.refreshToken) == RefreshToken
                            expect(newCredentials?.idToken) == NewIdToken
                            done()
                        }
                    }
                }

                it("should store new credentials") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: 2) { done in
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
                    waitUntil(timeout: 2) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(matchError(CredentialsManagerError.failedRefresh(AuthenticationError())))
                            expect(newCredentials).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should yield new credentials on explicit renew") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: 3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: 2) { done in
                        expect(credentialsManager.hasExpired(credentials)).to(beFalse())
                        credentialsManager.renew { error, newCredentials in
                            expect(newCredentials?.accessToken) == NewAccessToken
                            expect(newCredentials?.refreshToken) == RefreshToken
                            expect(newCredentials?.idToken) == NewIdToken
                            
                            credentialsManager.credentials { error, storedCredentials in
                                expect(storedCredentials?.accessToken) == newCredentials?.accessToken
                                expect(storedCredentials?.refreshToken) == newCredentials?.refreshToken
                                expect(storedCredentials?.idToken) == newCredentials?.idToken
                                done()
                            }
                        }
                    }
                }
                
                it("should yield error on failed explicit renew") {
                    stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in return authFailure(code: "invalid_request", description: "missing_params") }.name = "renew failed"
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: 2) { done in
                        expect(credentialsManager.hasExpired(credentials)).to(beTrue())
                        credentialsManager.renew { error, newCredentials in
                            expect(error).to(matchError(CredentialsManagerError.failedRefresh(AuthenticationError())))
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

