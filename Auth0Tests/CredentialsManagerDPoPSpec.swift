import Foundation
import Quick
import Nimble
import SimpleKeychain

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let TokenType = "bearer"
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewIdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Scope = "openid profile email"
private let ExpiresIn: TimeInterval = 3600
private let Timeout: NimbleTimeInterval = .seconds(2)
private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"

private class DPoPSpyStorage: CredentialsStorage {
    var store: [String: Data] = [:]
    func getEntry(forKey key: String) throws -> Data {
        guard let data = store[key] else { throw SimpleKeychainError.itemNotFound }
        return data
    }
    func setEntry(_ data: Data, forKey key: String) throws { store[key] = data }
    func deleteEntry(forKey key: String) throws { store.removeValue(forKey: key) }
}

class CredentialsManagerDPoPSpec: QuickSpec {

    override class func spec() {

        let dpopThumbprintKey = "dpop_thumbprint"

        var spyStorage: DPoPSpyStorage!

        beforeEach {
            spyStorage = DPoPSpyStorage()
            URLProtocol.registerClass(StubURLProtocol.self)
        }

        afterEach {
            NetworkStub.clearStubs()
            URLProtocol.unregisterClass(StubURLProtocol.self)
        }

        // MARK: - Non-DPoP credentials — validation is skipped

        describe("non-DPoP credentials") {

            it("should skip validation for non-DPoP credentials without stored thumbprint") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let dpopCredentials = Credentials(accessToken: AccessToken,
                                                  tokenType: TokenType,
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                  scope: Scope)
                try manager.store(credentials: dpopCredentials)
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) },
                                    response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresAt: ExpiresIn))
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

        }

        // MARK: - dpopNotConfigured

        describe("dpopNotConfigured") {

            it("should return dpopNotConfigured when DPoP credentials exist but authentication has no DPoP") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let dpopCredentials = Credentials(accessToken: AccessToken,
                                                  tokenType: "DPoP",
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                  scope: Scope)
                try manager.store(credentials: dpopCredentials)
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(.dpopNotConfigured))
                        done()
                    }
                }
            }

            it("should return dpopNotConfigured when stored thumbprint exists but authentication has no DPoP") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let bearerCredentials = Credentials(accessToken: AccessToken,
                                                    tokenType: TokenType,
                                                    idToken: IdToken,
                                                    refreshToken: RefreshToken,
                                                    expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                    scope: Scope)
                try manager.store(credentials: bearerCredentials)
                spyStorage.store[dpopThumbprintKey] = Data("some_thumbprint".utf8)
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(.dpopNotConfigured))
                        done()
                    }
                }
            }

        }

        // MARK: - dpopKeyMissing

        describe("dpopKeyMissing") {

            it("should return dpopKeyMissing and clear credentials when key pair is gone") {
                let keyStore = MockDPoPKeyStore(failHasPrivateKey: true)
                var auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                auth.dpop = DPoP(keyStore: keyStore)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let dpopCredentials = Credentials(accessToken: AccessToken,
                                                  tokenType: "DPoP",
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                  scope: Scope)
                try manager.store(credentials: dpopCredentials)
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(.dpopKeyMissing))
                        expect(spyStorage.store["credentials"]).to(beNil())
                        done()
                    }
                }
            }

            it("should return dpopKeyMissing via stored thumbprint when key pair is gone") {
                let keyStore = MockDPoPKeyStore(failHasPrivateKey: true)
                var auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                auth.dpop = DPoP(keyStore: keyStore)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let bearerCredentials = Credentials(accessToken: AccessToken,
                                                    tokenType: TokenType,
                                                    idToken: IdToken,
                                                    refreshToken: RefreshToken,
                                                    expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                    scope: Scope)
                try manager.store(credentials: bearerCredentials)
                spyStorage.store[dpopThumbprintKey] = Data("some_thumbprint".utf8)
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(.dpopKeyMissing))
                        expect(spyStorage.store["credentials"]).to(beNil())
                        done()
                    }
                }
            }

        }

        // MARK: - dpopKeyMismatch

        describe("dpopKeyMismatch") {

            it("should return dpopKeyMismatch and clear credentials when thumbprint does not match") {
                let keyStore = MockDPoPKeyStore()
                var auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                auth.dpop = DPoP(keyStore: keyStore)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let dpopCredentials = Credentials(accessToken: AccessToken,
                                                  tokenType: "DPoP",
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                  scope: Scope)
                try manager.store(credentials: dpopCredentials)
                spyStorage.store[dpopThumbprintKey] = Data("stale_thumbprint_from_old_key".utf8)
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(haveCredentialsManagerError(.dpopKeyMismatch))
                        expect(spyStorage.store["credentials"]).to(beNil())
                        done()
                    }
                }
            }

        }

        // MARK: - Validation passes

        describe("validation passes") {

            it("should pass validation and renew when DPoP is configured, key exists, and thumbprints match") {
                let keyStore = MockDPoPKeyStore()
                var auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                let dpop = DPoP(keyStore: keyStore)
                auth.dpop = dpop
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let currentThumbprint = try! dpop.jkt()
                let dpopCredentials = Credentials(accessToken: AccessToken,
                                                  tokenType: "DPoP",
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                  scope: Scope)
                try manager.store(credentials: dpopCredentials)
                spyStorage.store[dpopThumbprintKey] = Data(currentThumbprint.utf8)
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) },
                                    response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresAt: ExpiresIn))
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

            it("should pass validation when no thumbprint is stored and tokenType is DPoP") {
                let keyStore = MockDPoPKeyStore()
                var auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                auth.dpop = DPoP(keyStore: keyStore)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let dpopCredentials = Credentials(accessToken: AccessToken,
                                                  tokenType: "DPoP",
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                  scope: Scope)
                try manager.store(credentials: dpopCredentials)
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) },
                                    response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresAt: ExpiresIn))
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(beSuccessful())
                        done()
                    }
                }
            }

        }

        // MARK: - saveDPoPThumbprint

        describe("saveDPoPThumbprint") {

            it("should save DPoP thumbprint after successful renewal of DPoP-bound credentials") {
                let keyStore = MockDPoPKeyStore()
                var auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                let dpop = DPoP(keyStore: keyStore)
                auth.dpop = dpop
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let dpopCredentials = Credentials(accessToken: AccessToken,
                                                  tokenType: "DPoP",
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                  scope: Scope)
                try manager.store(credentials: dpopCredentials)
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) },
                                    response: authResponse(accessToken: NewAccessToken, tokenType: "DPoP", idToken: NewIdToken, expiresAt: ExpiresIn))
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(beSuccessful())
                        expect(spyStorage.store[dpopThumbprintKey]).toNot(beNil())
                        done()
                    }
                }
            }

            it("should not write a DPoP thumbprint after renewal of plain bearer credentials") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let bearerCredentials = Credentials(accessToken: AccessToken,
                                                    tokenType: TokenType,
                                                    idToken: IdToken,
                                                    refreshToken: RefreshToken,
                                                    expiresAt: Date(timeIntervalSinceNow: -ExpiresIn),
                                                    scope: Scope)
                try manager.store(credentials: bearerCredentials)
                NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) },
                                    response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, expiresAt: ExpiresIn))
                waitUntil(timeout: Timeout) { done in
                    manager.credentials { result in
                        expect(result).to(beSuccessful())
                        expect(spyStorage.store[dpopThumbprintKey]).to(beNil())
                        done()
                    }
                }
            }

        }

        // MARK: - clear()

        describe("clear") {

            it("should remove DPoP thumbprint when clear() is called") {
                let auth = Auth0.authentication(clientId: ClientId, domain: Domain)
                let manager = CredentialsManager(authentication: auth, storage: spyStorage)
                let credentials = Credentials(accessToken: AccessToken,
                                              tokenType: TokenType,
                                              idToken: IdToken,
                                              refreshToken: RefreshToken,
                                              expiresAt: Date(timeIntervalSinceNow: ExpiresIn),
                                              scope: Scope)
                try manager.store(credentials: credentials)
                spyStorage.store[dpopThumbprintKey] = Data("some_thumbprint".utf8)
                try manager.clear()
                expect(spyStorage.store[dpopThumbprintKey]).to(beNil())
            }

        }

    }
}
