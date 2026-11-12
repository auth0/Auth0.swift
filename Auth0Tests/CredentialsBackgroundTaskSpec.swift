import Foundation
import Quick
import Nimble

@testable import Auth0

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewAccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewIdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let RefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let NewRefreshToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let Audience = "https://example.com/api"
private let IssuedTokenType = "urn:auth0:params:oauth:token-type:session_transfer_token"
private let ExpiresIn: TimeInterval = 3600
private let Timeout: NimbleTimeInterval = .seconds(2)
private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"
private let SessionTransferAudience = "urn:\(Domain):session_transfer"
private let TaskIdentifier = 7

private final class SpyBackgroundTaskProvider: BackgroundTaskProvider, @unchecked Sendable {

    private let lock = NSLock()
    private var names: [String] = []
    private var identifiers: [Int] = []
    private var expirationHandler: (@MainActor @Sendable () -> Void)?

    var identifierToReturn: Int? = TaskIdentifier
    var expiresWhileStarting = false
    var onEnd: (() -> Void)?

    var startedNames: [String] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.names
    }

    var endedIdentifiers: [Int] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.identifiers
    }

    func begin(name: String, expirationHandler: @escaping @MainActor @Sendable () -> Void) -> Int? {
        self.lock.lock()
        self.names.append(name)
        self.expirationHandler = expirationHandler
        self.lock.unlock()
        if self.expiresWhileStarting {
            MainActor.assumeIsolated { expirationHandler() }
        }
        return self.identifierToReturn
    }

    func end(identifier: Int) {
        self.lock.lock()
        self.identifiers.append(identifier)
        self.lock.unlock()
        self.onEnd?()
    }

    @MainActor
    func expire() {
        self.expirationHandler?()
    }

}

private func refreshToken(in storage: SpyCredentialsStorage) -> String? {
    guard let data = try? storage.getEntry(forKey: "credentials") else { return nil }
    return (try? NSKeyedUnarchiver.unarchivedObject(ofClass: Credentials.self, from: data))?.refreshToken
}

class CredentialsBackgroundTaskSpec: QuickSpec {

    override class func spec() {

        describe("background task") {

            var provider: SpyBackgroundTaskProvider!

            beforeEach {
                provider = SpyBackgroundTaskProvider()
            }

            it("should start a task with the given name") {
                _ = CredentialsBackgroundTask(name: "foo", provider: provider)

                expect(provider.startedNames) == ["foo"]
                expect(provider.endedIdentifiers).to(beEmpty())
            }

            it("should end the task") {
                let task = CredentialsBackgroundTask(name: "foo", provider: provider)

                task.end()

                expect(provider.endedIdentifiers) == [TaskIdentifier]
            }

            it("should end the task only once when ending it twice") {
                let task = CredentialsBackgroundTask(name: "foo", provider: provider)

                task.end()
                task.end()

                expect(provider.endedIdentifiers) == [TaskIdentifier]
            }

            it("should end the task when it expires") {
                _ = CredentialsBackgroundTask(name: "foo", provider: provider)

                waitUntil(timeout: Timeout) { done in
                    Task { @MainActor in
                        provider.expire()
                        done()
                    }
                }

                expect(provider.endedIdentifiers) == [TaskIdentifier]
            }

            it("should not end the task again after it expires") {
                let task = CredentialsBackgroundTask(name: "foo", provider: provider)

                waitUntil(timeout: Timeout) { done in
                    Task { @MainActor in
                        provider.expire()
                        done()
                    }
                }
                task.end()

                expect(provider.endedIdentifiers) == [TaskIdentifier]
            }

            it("should end the task when it expires before it finishes starting") {
                provider.expiresWhileStarting = true

                _ = CredentialsBackgroundTask(name: "foo", provider: provider)

                expect(provider.endedIdentifiers) == [TaskIdentifier]
            }

            it("should not end a task that did not start") {
                provider.identifierToReturn = nil
                let task = CredentialsBackgroundTask(name: "foo", provider: provider)

                task.end()

                expect(provider.endedIdentifiers).to(beEmpty())
            }

        }

        describe("system background task provider") {

            #if canImport(UIKit) && !os(watchOS)
            it("should start and end a task from a background thread") {
                waitUntil(timeout: Timeout) { done in
                    DispatchQueue.global().async {
                        let provider = SystemBackgroundTaskProvider()
                        let identifier = provider.begin(name: "foo") {}
                        expect(identifier).toNot(beNil())
                        if let identifier = identifier {
                            provider.end(identifier: identifier)
                        }
                        done()
                    }
                }
            }
            #else
            it("should not start a task") {
                expect(SystemBackgroundTaskProvider().begin(name: "foo") {}).to(beNil())
            }
            #endif

        }

        describe("credentials manager") {

            let authentication = Auth0.authentication(clientId: ClientId, domain: Domain)
            var provider: SpyBackgroundTaskProvider!
            var storage: SpyCredentialsStorage!
            var credentialsManager: CredentialsManager!
            var expiredCredentials: Credentials!

            beforeEach {
                provider = SpyBackgroundTaskProvider()
                storage = SpyCredentialsStorage()
                credentialsManager = CredentialsManager(authentication: authentication, storage: storage)
                credentialsManager.backgroundTaskProvider = provider
                expiredCredentials = Credentials(accessToken: AccessToken,
                                                 idToken: IdToken,
                                                 refreshToken: RefreshToken,
                                                 expiresAt: Date(timeIntervalSinceNow: -ExpiresIn))
                URLProtocol.registerClass(StubURLProtocol.self)
            }

            afterEach {
                NetworkStub.clearStubs()
                URLProtocol.unregisterClass(StubURLProtocol.self)
            }

            it("should use the system provider by default") {
                expect(CredentialsManager(authentication: authentication).backgroundTaskProvider is SystemBackgroundTaskProvider) == true
            }

            describe("credentials") {

                it("should start the task before the request and end it after storing the new credentials") {
                    var startedAtRequest: Int?
                    var endedAtRequest: Int?
                    var refreshTokenAtEnd: String?
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) }) { request in
                        startedAtRequest = provider.startedNames.count
                        endedAtRequest = provider.endedIdentifiers.count
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresAt: ExpiresIn)(request)
                    }
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = {
                            refreshTokenAtEnd = refreshToken(in: storage)
                            done()
                        }
                        credentialsManager.credentials { _ in }
                    }

                    expect(startedAtRequest) == 1
                    expect(endedAtRequest) == 0
                    expect(refreshTokenAtEnd) == NewRefreshToken
                    expect(provider.startedNames) == ["Auth0.credentials"]
                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

                it("should not start a task when no renewal is needed") {
                    let credentials = Credentials(accessToken: AccessToken,
                                                  idToken: IdToken,
                                                  refreshToken: RefreshToken,
                                                  expiresAt: Date(timeIntervalSinceNow: ExpiresIn))
                    try? credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beSuccessful())
                            done()
                        }
                    }

                    expect(provider.startedNames).to(beEmpty())
                }

                it("should not start a task when there are no credentials") {
                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(beUnsuccessful())
                            done()
                        }
                    }

                    expect(provider.startedNames).to(beEmpty())
                }

                it("should not start a task when there is no refresh token") {
                    let credentials = Credentials(accessToken: AccessToken,
                                                  idToken: IdToken,
                                                  refreshToken: nil,
                                                  expiresAt: Date(timeIntervalSinceNow: -ExpiresIn))
                    try? credentialsManager.store(credentials: credentials)

                    waitUntil(timeout: Timeout) { done in
                        credentialsManager.credentials { result in
                            expect(result).to(haveCredentialsManagerError(.noRefreshToken))
                            done()
                        }
                    }

                    expect(provider.startedNames).to(beEmpty())
                }

                it("should start one task for many calls that wait for the same renewal") {
                    var requests = 0
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) }) { request in
                        requests += 1
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresAt: ExpiresIn)(request)
                    }
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        let calls = 20
                        var finished = 0
                        for _ in 1...calls {
                            credentialsManager.credentials { result in
                                expect(result).to(beSuccessful())
                                finished += 1
                                if finished == calls {
                                    done()
                                }
                            }
                        }
                    }

                    expect(requests) == 1
                    expect(provider.startedNames) == ["Auth0.credentials"]
                }

                it("should end the task when the renewal fails") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) }, response: authFailure(code: "invalid_grant", description: "Unknown or invalid refresh token."))
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = { done() }
                        credentialsManager.credentials { _ in }
                    }

                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                    expect(refreshToken(in: storage)) == RefreshToken
                }

                it("should keep one task running across retries") {
                    var attempts = 0
                    var endedAtRetry: Int?
                    credentialsManager = CredentialsManager(authentication: authentication, storage: storage, maxRetries: 1)
                    credentialsManager.backgroundTaskProvider = provider
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) }) { request in
                        attempts += 1
                        if attempts == 1 {
                            return networkErrorResponse(code: .timedOut)(request)
                        }
                        endedAtRetry = provider.endedIdentifiers.count
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresAt: ExpiresIn)(request)
                    }
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: .seconds(5)) { done in
                        provider.onEnd = { done() }
                        credentialsManager.credentials { _ in }
                    }

                    expect(attempts) == 2
                    expect(endedAtRetry) == 0
                    expect(provider.startedNames) == ["Auth0.credentials"]
                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                    expect(refreshToken(in: storage)) == NewRefreshToken
                }

                it("should end the task when a retry finds no credentials") {
                    var attempts = 0
                    credentialsManager = CredentialsManager(authentication: authentication, storage: storage, maxRetries: 1)
                    credentialsManager.backgroundTaskProvider = provider
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) }) { request in
                        attempts += 1
                        storage.store.removeAll()
                        return networkErrorResponse(code: .timedOut)(request)
                    }
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: .seconds(5)) { done in
                        provider.onEnd = { done() }
                        credentialsManager.credentials { _ in }
                    }

                    expect(attempts) == 1
                    expect(provider.startedNames) == ["Auth0.credentials"]
                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

                it("should use a task with the async API") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) }, response: authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresAt: ExpiresIn))
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = { done() }
                        Task { _ = try? await credentialsManager.credentials() }
                    }

                    expect(provider.startedNames) == ["Auth0.credentials"]
                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

            }

            describe("renew") {

                it("should start the task before the request and end it after storing the new credentials") {
                    var startedAtRequest: Int?
                    var endedAtRequest: Int?
                    var refreshTokenAtEnd: String?
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken]) }) { request in
                        startedAtRequest = provider.startedNames.count
                        endedAtRequest = provider.endedIdentifiers.count
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresAt: ExpiresIn)(request)
                    }
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = {
                            refreshTokenAtEnd = refreshToken(in: storage)
                            done()
                        }
                        credentialsManager.renew { _ in }
                    }

                    expect(startedAtRequest) == 1
                    expect(endedAtRequest) == 0
                    expect(refreshTokenAtEnd) == NewRefreshToken
                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

            }

            describe("API credentials") {

                it("should start the task before the request and end it after storing the new credentials") {
                    var startedAtRequest: Int?
                    var endedAtRequest: Int?
                    var refreshTokenAtEnd: String?
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": Audience]) }) { request in
                        startedAtRequest = provider.startedNames.count
                        endedAtRequest = provider.endedIdentifiers.count
                        return authResponse(accessToken: NewAccessToken, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresAt: ExpiresIn)(request)
                    }
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = {
                            refreshTokenAtEnd = refreshToken(in: storage)
                            done()
                        }
                        credentialsManager.apiCredentials(forAudience: Audience) { _ in }
                    }

                    expect(startedAtRequest) == 1
                    expect(endedAtRequest) == 0
                    expect(refreshTokenAtEnd) == NewRefreshToken
                    expect(provider.startedNames) == ["Auth0.apiCredentials"]
                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

                it("should end the task when the exchange fails") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) }, response: authFailure(code: "invalid_grant", description: "Unknown or invalid refresh token."))
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = { done() }
                        credentialsManager.apiCredentials(forAudience: Audience) { _ in }
                    }

                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

            }

            describe("SSO credentials") {

                it("should start the task before the request and end it after storing the new credentials") {
                    var startedAtRequest: Int?
                    var endedAtRequest: Int?
                    var refreshTokenAtEnd: String?
                    NetworkStub.addStub(condition: { $0.isToken(Domain) && $0.hasAtLeast(["refresh_token": RefreshToken, "audience": SessionTransferAudience]) }) { request in
                        startedAtRequest = provider.startedNames.count
                        endedAtRequest = provider.endedIdentifiers.count
                        return authResponse(accessToken: NewAccessToken, issuedTokenType: IssuedTokenType, idToken: NewIdToken, refreshToken: NewRefreshToken, expiresAt: ExpiresIn)(request)
                    }
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = {
                            refreshTokenAtEnd = refreshToken(in: storage)
                            done()
                        }
                        credentialsManager.ssoCredentials { _ in }
                    }

                    expect(startedAtRequest) == 1
                    expect(endedAtRequest) == 0
                    expect(refreshTokenAtEnd) == NewRefreshToken
                    expect(provider.startedNames) == ["Auth0.ssoCredentials"]
                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

                it("should end the task when the exchange fails") {
                    NetworkStub.addStub(condition: { $0.isToken(Domain) }, response: authFailure(code: "invalid_grant", description: "Unknown or invalid refresh token."))
                    try? credentialsManager.store(credentials: expiredCredentials)

                    waitUntil(timeout: Timeout) { done in
                        provider.onEnd = { done() }
                        credentialsManager.ssoCredentials { _ in }
                    }

                    expect(provider.endedIdentifiers) == [TaskIdentifier]
                }

            }

        }

    }

}
