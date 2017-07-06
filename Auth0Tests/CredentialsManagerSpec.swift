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
import LocalAuthentication

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let TokenType = "bearer"
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
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

            it("should store credentials in keychain") {
                expect(credentialsManager.store(credentials: credentials)).to(beTrue())
            }

            it("should clear credentials in keychain") {
                expect(credentialsManager.clearCredentials()).to(beTrue())
            }

            it("should fail to clear credentials") {
                expect(credentialsManager.clearCredentials()).to(beFalse())
            }

        }

        describe("retrieval") {

            var error: Error?
            var newCredentials: Credentials?

            beforeEach {
                error = nil
                newCredentials = nil
                stub(condition: isToken(Domain) && hasAtLeast(["refresh_token": RefreshToken])) { _ in return authResponse(accessToken: AccessToken) }.name = "renew success"
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

            it("should error when no refresh_token present and token expired") {
                credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: nil, expiresIn: Date(timeIntervalSinceNow: -ExpiresIn))
                _ = credentialsManager.store(credentials: credentials)
                credentialsManager.credentials { error = $0; newCredentials = $1 }
                expect(error).to(matchError(CredentialsManagerError.noRefreshToken))
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

            context("require touch") {

                beforeEach {
                    credentialsManager.enableTouchAuth(withTitle: "Auth Title", cancelTitle: "Cancel Title", fallbackTitle: "Fallback Title")
                }

                it("should error when touch unavailable") {
                    waitUntil(timeout: 2) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(matchError(CredentialsManagerError.touchFailed(LAError(LAError.touchIDNotAvailable))))
                            expect(newCredentials).to(beNil())
                            done()
                        }
                    }
                }

            }

            context("renew") {

                it("should yield new credentials") {
                    credentials = Credentials(accessToken: AccessToken, tokenType: TokenType, idToken: IdToken, refreshToken: RefreshToken, expiresIn: Date(timeIntervalSinceNow: -3600))
                    _ = credentialsManager.store(credentials: credentials)
                    waitUntil(timeout: 2) { done in
                        credentialsManager.credentials { error = $0; newCredentials = $1
                            expect(error).to(beNil())
                            expect(newCredentials?.accessToken) == AccessToken
                            done()
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
            
        }
    }
}

