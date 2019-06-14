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
#if os(iOS)
import LocalAuthentication
#endif

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let TokenType = "bearer"
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewIdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let ExpiresIn: TimeInterval = 3600
private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"

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
        
        describe("multi instances of credentials manager") {
            
            var secondaryCredentialsManager: CredentialsManager!
            var secondaryCredentials: Credentials!

            beforeEach {
                secondaryCredentialsManager = CredentialsManager(authentication: authentication, storeKey: "secondary_store")
                secondaryCredentials = Credentials(accessToken: "SecondaryAccessToken", tokenType: TokenType, idToken: "SecondaryIdToken", refreshToken: "SecondaryRefreshToken", expiresIn: Date(timeIntervalSinceNow: 10))
            }
            
            it("should store credentials into distinct locations") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
                expect(secondaryCredentialsManager.store(credentials: secondaryCredentials)).to(beTrue())
                                
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

        describe("retrieval") {

            var error: Error?
            var newCredentials: Credentials?

            beforeEach {
                error = nil
                newCredentials = nil
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresIn: 86400) }.name = "renew success"
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

                it("should yield new credentials, maintain refresh token") {
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
            }
            
            context("custom keychain", closure: {
                beforeEach {
                    let storage = A0SimpleKeychain(service: "test_service")
                    credentialsManager = CredentialsManager(authentication: authentication,
                                                            storage: storage)
                }
                
                it("should accept custom keychains") {
                    expect(credentialsManager.storage.service).to(match("test_service"))
                }
            })
        }
    }
}

