import Quick
import Nimble
import SafariServices

@testable import Auth0

private let ClientId = "ClientId"
private let Domain = "samples.auth0.com"
private let DomainURL = URL.httpsURL(from: Domain)
private let RedirectURL = URL(string: "https://samples.auth0.com/callback")!
private let State = "state"

extension URL {
    var a0_components: URLComponents? {
        return URLComponents(url: self, resolvingAgainstBaseURL: true)
    }
}

class ValidAuthorizeURLBehavior: Behavior<[String:Any]> {
    override class func spec(_ aContext: @escaping () -> [String : Any]) {
        var context: [String:Any]!
        var components: URLComponents!
        
        beforeEach {
            context = aContext()
            let url = context["url"] as! URL
            components = url.a0_components
        }
        
        it("should use domain") {
            expect(components?.scheme) == "https"
            let domain = context["domain"] as! String
            expect(components?.host) == String(domain.split(separator: "/").first!)
            expect(components?.path).to(endWith("/authorize"))
        }
        
        it("should have state parameter") {
            expect(components?.queryItems).to(containItem(withName:"state"))
        }
        
        it("should have query parameters") {
            let params = context["query"] as! [String: String]
            params.forEach { key, value in
                expect(components?.queryItems).to(containItem(withName: key, value: value))
            }
        }
    }
}

private func newWebAuth() -> Auth0WebAuth {
    return Auth0WebAuth(clientId: ClientId, url: DomainURL, barrier: MockBarrier())
}

private func defaultQuery(withParameters parameters: [String: String] = [:]) -> [String: String] {
    var query = [
        "client_id": ClientId,
        "response_type": "code",
        "redirect_uri": RedirectURL.absoluteString,
        "scope": defaultScope,
    ]
    parameters.forEach { query[$0] = $1 }
    return query
}

private let defaults = ["response_type": "code"]

class WebAuthSpec: QuickSpec {

    override class func spec() {

        describe("init") {

            it("should init with client id & url") {
                let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL)
                expect(webAuth.clientId) == ClientId
                expect(webAuth.url) == DomainURL
            }

            it("should init with client id, url & session") {
                let session = URLSession(configuration: URLSession.shared.configuration)
                let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL, session: session)
                expect(webAuth.session).to(be(session))
            }

            it("should init with client id, url & storage") {
                let storage = TransactionStore()
                let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL, storage: storage)
                expect(webAuth.storage).to(be(storage))
            }

            it("should init with client id, url & telemetry") {
                let telemetryInfo = "info"
                var telemetry = Telemetry()
                telemetry.info = telemetryInfo
                let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL, telemetry: telemetry)
                expect(webAuth.telemetry.info) == telemetryInfo
            }

            it("should init with client id, url & barrier") {
                let barrier = QueueBarrier.shared
                let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL, barrier: barrier)
                expect(webAuth.barrier).to(be(barrier))
            }

        }

        describe("authorize URL") {

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": "\(Domain)/foo",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": "\(Domain)/foo/",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": "\(Domain)/foo/bar",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": "\(Domain)/foo/bar/",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .connection("facebook")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection": "facebook"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let state = UUID().uuidString
                return [
                    "url": newWebAuth()
                        .state(state)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["state": state]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let scope = "openid email phone"
                return [
                    "url": newWebAuth()
                        .scope(scope)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["scope": scope]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let scope = "email phone"
                return [
                    "url": newWebAuth()
                        .scope(scope)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["scope": "openid \(scope)"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .maxAge(10000) // 1 second
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["max_age": "10000"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: "abc1234", invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": "abc1234"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: "abc1234", invitation: "xyz6789"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": "abc1234", "invitation": "xyz6789"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                var newDefaults = defaults
                newDefaults["audience"] = "https://wwww.google.com"
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://wwww.google.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                var newDefaults = defaults
                newDefaults["audience"] = "https://wwww.google.com"
                return [
                    "url": newWebAuth()
                        .audience("https://domain.auth0.com")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .audience("https://domain.auth0.com")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .connectionScope("user_friends,email")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection_scope": "user_friends,email"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                var newDefaults = defaults
                newDefaults["connection_scope"] = "email"
                return [
                    "url": newWebAuth()
                        .connectionScope("user_friends")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection_scope": "user_friends"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let organization = "foo"
                let invitation = "bar"
                let url = URL(string: "https://example.com?organization=\(organization)&invitation=\(invitation)")!
                return [
                    "url": newWebAuth()
                        .invitationURL(url)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: organization, invitation: invitation),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": organization, "invitation": invitation]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": newWebAuth()
                        .authorizeURL(URL(string: "https://example.com/authorize")!)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": "example.com",
                    "query": defaultQuery(),
                ]
            }

            context("encoding") {
                
                it("should encode + as %2B"){
                    let url = newWebAuth()
                            .parameters(["login_hint": "first+last@host.com"])
                            .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil)
                    expect(url.absoluteString.contains("first%2Blast@host.com")).to(beTrue())
                }
                
            }

            it("should build with a custom authorize url") {
                let url = URL(string: "https://example.com/authorize")!
                expect(newWebAuth().authorizeURL(url).overrideAuthorizeURL) == url
            }
        }

        describe("redirect uri") {
            let bundleId = Bundle.main.bundleIdentifier!
            let platform: String

            #if os(iOS)
            platform = "ios"
            #elseif os(visionOS)
            platform = "visionos"
            #else
            platform = "macos"
            #endif

            #if compiler(>=5.10)
            if #available(iOS 17.4, macOS 14.4, visionOS 1.2, *) {
                context("https") {
                    it("should build with the domain") {
                        expect(newWebAuth().useHTTPS().redirectURL?.absoluteString) == "https://\(Domain)/\(platform)/\(bundleId)/callback"
                    }

                    it("should build with the domain and a subpath") {
                        let subpath = "foo"
                        let uri = "https://\(Domain)/\(subpath)/\(platform)/\(bundleId)/callback"
                        let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL.appendingPathComponent(subpath)).useHTTPS()
                        expect(webAuth.redirectURL?.absoluteString) == uri
                    }

                    it("should build with the domain and subpaths") {
                        let subpaths = "foo/bar"
                        let uri = "https://\(Domain)/\(subpaths)/\(platform)/\(bundleId)/callback"
                        let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL.appendingPathComponent(subpaths)).useHTTPS()
                        expect(webAuth.redirectURL?.absoluteString) == uri
                    }
                }
            }
            #endif

            context("custom scheme") {

                it("should build with the domain") {
                    expect(newWebAuth().redirectURL?.absoluteString) == "\(bundleId)://\(Domain)/\(platform)/\(bundleId)/callback"
                }

                it("should build with the domain and a subpath") {
                    let subpath = "foo"
                    let uri = "\(bundleId)://\(Domain)/\(subpath)/\(platform)/\(bundleId)/callback"
                    let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL.appendingPathComponent(subpath))
                    expect(webAuth.redirectURL?.absoluteString) == uri
                }

                it("should build with the domain and subpaths") {
                    let subpaths = "foo/bar"
                    let uri = "\(bundleId)://\(Domain)/\(subpaths)/\(platform)/\(bundleId)/callback"
                    let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL.appendingPathComponent(subpaths))
                    expect(webAuth.redirectURL?.absoluteString) == uri
                }

            }

            it("should build with a custom url") {
                expect(newWebAuth().redirectURL(RedirectURL).redirectURL) == RedirectURL
            }

        }

        describe("other builder methods") {

            #if compiler(>=5.10)
            if #available(iOS 17.4, macOS 14.4, visionOS 1.2, *) {
                context("custom headers") {

                    it("should not add custom headers by default") {
                        expect(newWebAuth().headers).to(beEmpty())
                    }

                    it("should add custom headers") {
                        let headers = ["X-Foo": "Bar", "X-Baz": "Qux"]
                        expect(newWebAuth().headers(headers).headers).to(equal(headers))
                    }

                }
            }
            #endif

            context("https") {

                it("should not use https callbacks by default") {
                    expect(newWebAuth().https).to(beFalse())
                }

                it("should use https callbacks") {
                    expect(newWebAuth().useHTTPS().https).to(beTrue())
                }

            }

            context("ephemeral session") {

                it("should not use ephemeral session by default") {
                    expect(newWebAuth().ephemeralSession).to(beFalse())
                }

                it("should use ephemeral session") {
                    expect(newWebAuth().useEphemeralSession().ephemeralSession).to(beTrue())
                }

            }

            context("nonce") {

                it("should not use a custom nonce value by default") {
                    expect(newWebAuth().nonce).to(beNil())
                }

                it("should use a custom nonce value") {
                    let nonce = "foo"
                    expect(newWebAuth().nonce(nonce).nonce).to(equal(nonce))
                }

            }

            context("leeway") {

                it("should use the default leeway value") {
                    expect(newWebAuth().leeway).to(equal(60000)) // 60 seconds
                }

                it("should use a custom leeway value") {
                    expect(newWebAuth().leeway(30000).leeway).to(equal(30000)) // 30 seconds
                }

            }

            context("issuer") {

                it("should use the default issuer value") {
                    expect(newWebAuth().issuer).to(equal(DomainURL.absoluteString))
                }

                it("should use a custom issuer value") {
                    expect(newWebAuth().issuer("https://example.com/").issuer).to(equal("https://example.com/"))
                }

            }

            context("organization") {

                it("should use no organization value by default") {
                    expect(newWebAuth().organization).to(beNil())
                }

                it("should use an organization value") {
                    expect(newWebAuth().organization("abc1234").organization).to(equal("abc1234"))
                }

            }

            context("organization invitation") {

                it("should use no organization invitation URL by default") {
                    expect(newWebAuth().invitationURL).to(beNil())
                }

                it("should use an organization invitation URL") {
                    let invitationUrl = URL(string: "https://example.com/")!
                    expect(newWebAuth().invitationURL(invitationUrl).invitationURL?.absoluteString).to(equal("https://example.com/"))
                }

            }

            context("provider") {

                it("should use no custom provider by default") {
                    expect(newWebAuth().provider).to(beNil())
                }

                it("should use a custom provider") {
                    expect(newWebAuth().provider(WebAuthentication.asProvider(redirectURL: RedirectURL)).provider).toNot(beNil())
                }

            }

            context("onClose") {

                it("should use no onCloseCallback by default") {
                    expect(newWebAuth().onCloseCallback).to(beNil())
                }

                it("should use an onCloseCallback") {
                    expect(newWebAuth().onClose({ /* Empty */ }).onCloseCallback).toNot(beNil())
                }

            }

        }

        #if os(iOS) || os(visionOS)
        describe("login") {

            var auth: Auth0WebAuth!

            beforeEach {
                auth = newWebAuth()
                TransactionStore.shared.clear()
            }

            it("should start the supplied provider") {
                var isStarted = false
                _ = auth.provider({ url, _ in
                    isStarted = true
                    return SpyUserAgent()
                })
                auth.start { _ in }
                expect(isStarted).toEventually(beTrue())
            }

            it("should generate a state") {
                _ = auth.provider({ url, _ in SpyUserAgent() })
                auth.start { _ in }
                expect(auth.state).toNot(beNil())
            }

            it("should generate different state on every start") {
                _ = auth.provider({ url, _ in SpyUserAgent() })
                auth.start { _ in }
                let state = auth.state
                auth.start { _ in }
                expect(auth.state) != state
            }

            it("should use the supplied state") {
                _ = auth.provider({ url, _ in SpyUserAgent() })
                let state = UUID().uuidString
                auth.state(state).start { _ in }
                expect(auth.state) == state
            }

            it("should use the state supplied via parameters") {
                _ = auth.provider({ url, _ in SpyUserAgent() })
                let state = UUID().uuidString
                auth.parameters(["state": state]).start { _ in }
                expect(auth.state) == state
            }

            it("should use the organization and invitation from the invitation URL") {
                let url = "https://\(Domain)?organization=foo&invitation=bar"
                var redirectURL: URL?
                _ = auth.invitationURL(URL(string: url)!).provider({ url, _ in
                    redirectURL = url
                    return SpyUserAgent()
                })
                auth.start { _ in }
                expect(redirectURL?.query).toEventually(contain("organization=foo"))
                expect(redirectURL?.query).toEventually(contain("invitation=bar"))
            }

            it("should produce an invalid invitation URL error when the organization is missing") {
                let url = "https://\(Domain)?invitation=foo"
                let expectedError = WebAuthError(code: .invalidInvitationURL(url))
                var result: WebAuthResult<Credentials>?
                _ = auth.invitationURL(URL(string: url)!)
                auth.start { result = $0 }
                expect(result).toEventually(haveWebAuthError(expectedError))
            }

            it("should produce an invalid invitation URL error when the invitation is missing") {
                let url = "https://\(Domain)?organization=foo"
                let expectedError = WebAuthError(code: .invalidInvitationURL(url))
                var result: WebAuthResult<Credentials>?
                _ = auth.invitationURL(URL(string: url)!)
                auth.start { result = $0 }
                expect(result).toEventually(haveWebAuthError(expectedError))
            }

            it("should produce an invalid invitation URL error when the organization and invitation are missing") {
                let url = "https://\(Domain)?foo=bar"
                let expectedError = WebAuthError(code: .invalidInvitationURL(url))
                var result: WebAuthResult<Credentials>?
                _ = auth.invitationURL(URL(string: url)!)
                auth.start { result = $0 }
                expect(result).toEventually(haveWebAuthError(expectedError))
            }

            it("should produce an invalid invitation URL error when the query parameters are missing") {
                let expectedError = WebAuthError(code: .invalidInvitationURL(DomainURL.absoluteString))
                var result: WebAuthResult<Credentials>?
                _ = auth.invitationURL(DomainURL)
                auth.start { result = $0 }
                expect(result).toEventually(haveWebAuthError(expectedError))
            }

            it("should produce a no bundle identifier error when redirect URL is missing") {
                let expectedError = WebAuthError(code: .noBundleIdentifier)
                var result: WebAuthResult<Credentials>?
                auth.redirectURL = nil
                auth.start { result = $0 }
                expect(result).toEventually(haveWebAuthError(expectedError))
            }

            context("transaction") {

                beforeEach {
                    TransactionStore.shared.clear()
                }

                it("should store a new transaction") {
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { _ in }
                    expect(TransactionStore.shared.current).toNot(beNil())
                    TransactionStore.shared.cancel()
                }

                it("should cancel the current transaction") {
                    var result: WebAuthResult<Credentials>?
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { result = $0 }
                    TransactionStore.shared.cancel()
                    expect(result).toEventually(haveWebAuthError(WebAuthError(code: .userCancelled)))
                    expect(TransactionStore.shared.current).to(beNil())
                }

            }

            context("barrier") {

                beforeEach {
                    auth = Auth0WebAuth(clientId: ClientId, url: DomainURL, barrier: QueueBarrier.shared)
                    QueueBarrier.shared.lower()
                }

                it("should raise the barrier") {
                    let expectedError = WebAuthError(code: .transactionActiveAlready)
                    var result: WebAuthResult<Credentials>?
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { _ in }
                    auth.start { result = $0 }
                    expect(result).toEventually(haveWebAuthError(expectedError))
                }

                it("should lower the barrier") {
                    var firstResult: WebAuthResult<Credentials>?
                    var secondResult: WebAuthResult<Credentials>?
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { firstResult = $0 }
                    TransactionStore.shared.cancel()
                    expect(firstResult).toEventually(haveWebAuthError(WebAuthError(code: .userCancelled)))
                    auth.start { secondResult = $0 }
                    expect(secondResult).toEventually(beNil())
                }

            }

        }

        describe("logout") {

            var auth: Auth0WebAuth!

            beforeEach {
                auth = newWebAuth()
                TransactionStore.shared.clear()
            }

            it("should start the supplied provider") {
                var isStarted = false
                _ = auth.provider({ url, _ in
                    isStarted = true
                    return SpyUserAgent()
                })
                auth.start { _ in }
                expect(isStarted).toEventually(beTrue())
            }

            it("should not include the federated parameter by default") {
                var redirectURL: URL?
                _ = auth.provider({ url, _ in
                    redirectURL = url
                    return SpyUserAgent()
                })
                auth.clearSession() { _ in }
                expect(redirectURL?.query?.contains("federated")).toEventually(beFalse())
            }

            it("should include the federated parameter") {
                var redirectURL: URL?
                _ = auth.provider({ url, _ in
                    redirectURL = url
                    return SpyUserAgent()
                })
                auth.clearSession(federated: true) { _ in }
                expect(redirectURL?.query?.contains("federated")).toEventually(beTrue())
            }

            it("should produce a no bundle identifier error when redirect URL is missing") {
                var result: WebAuthResult<Void>?
                auth.redirectURL = nil
                auth.clearSession() { result = $0 }
                expect(result).to(haveWebAuthError(WebAuthError(code: .noBundleIdentifier)))
            }

            context("transaction") {

                var result: WebAuthResult<Void>?

                beforeEach {
                    result = nil
                    TransactionStore.shared.clear()
                }

                it("should store a new transaction") {
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.clearSession() { _ in }
                    expect(TransactionStore.shared.current).toNot(beNil())
                }

                it("should cancel the current transaction") {
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.clearSession() { result = $0 }
                    TransactionStore.shared.cancel()
                    expect(result).toEventually(haveWebAuthError(WebAuthError(code: .userCancelled)))
                    expect(TransactionStore.shared.current).to(beNil())
                }

                it("should resume the current transaction") {
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.clearSession() { result = $0 }
                    _ = TransactionStore.shared.resume(URL(string: "http://fake.com")!)
                    expect(result).toEventually(beSuccessful())
                    expect(TransactionStore.shared.current).to(beNil())
                }

            }

            context("barrier") {

                beforeEach {
                    auth = Auth0WebAuth(clientId: ClientId, url: DomainURL, barrier: QueueBarrier.shared)
                    QueueBarrier.shared.lower()
                }

                it("should raise the barrier") {
                    let expectedError = WebAuthError(code: .transactionActiveAlready)
                    var result: WebAuthResult<Void>?
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.clearSession { _ in }
                    auth.clearSession { result = $0 }
                    expect(result).toEventually(haveWebAuthError(expectedError))
                }

                it("should lower the barrier") {
                    var firstResult: WebAuthResult<Void>?
                    var secondResult: WebAuthResult<Void>?
                    _ = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.clearSession { firstResult = $0 }
                    TransactionStore.shared.cancel()
                    expect(firstResult).toEventually(haveWebAuthError(WebAuthError(code: .userCancelled)))
                    auth.clearSession { secondResult = $0 }
                    expect(secondResult).toEventually(beNil())
                }

            }

        }
        #endif

    }

}

// - MARK: Mocks

class MockBarrier: Barrier {

    func raise() -> Bool {
        return true
    }

    func lower() {}

}

class MockUserAgent: WebAuthUserAgent {

    let callback: WebAuthProviderCallback

    init(callback: @escaping WebAuthProviderCallback) {
        self.callback = callback
    }

    func start() {}

    func finish(with result: WebAuthResult<Void>) {
        self.callback(result)
    }

}
