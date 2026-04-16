import Quick
import Combine
import Nimble
import SafariServices

@testable import Auth0

private let ClientId = "ClientId"
private let Domain = "samples.auth0.com"
private let DomainURL = URL.httpsURL(from: Domain)
private let RedirectURL = URL(string: "https://samples.auth0.com/callback")!
private let State = "state"
private let Nonce = "nonce"

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

            it("should init with client id, url & auth0ClientInfo") {
                let telemetryInfo = "info"
                var auth0ClientInfo = Auth0ClientInfo()
                auth0ClientInfo.info = telemetryInfo
                let webAuth = Auth0WebAuth(clientId: ClientId, url: DomainURL, auth0ClientInfo: auth0ClientInfo)
                expect(webAuth.auth0ClientInfo.info) == telemetryInfo
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
                    "url": try! newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": "\(Domain)/foo",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": "\(Domain)/foo/",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": "\(Domain)/foo/bar",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": "\(Domain)/foo/bar/",
                    "query": defaultQuery()
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .connection("facebook")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection": "facebook"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let state = UUID().uuidString
                return [
                    "url": try! newWebAuth()
                        .state(state)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["state": state]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let scope = "openid email phone"
                return [
                    "url": try! newWebAuth()
                        .scope(scope)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["scope": scope]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let scope = "email phone"
                return [
                    "url": try! newWebAuth()
                        .scope(scope)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["scope": "openid \(scope)"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .maxAge(10000) // 1 second
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["max_age": "10000"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .organization("abc1234")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": "abc1234"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .organization("abc1234")
                        .invitationURL(URL(string: "https://example.com/invitations?organization=abc1234&invitation=xyz6789")!)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": "abc1234", "invitation": "xyz6789"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                var newDefaults = defaults
                newDefaults["audience"] = "https://wwww.google.com"
                return [
                    "url": try! newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://wwww.google.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                var newDefaults = defaults
                newDefaults["audience"] = "https://wwww.google.com"
                return [
                    "url": try! newWebAuth()
                        .audience("https://domain.auth0.com")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .audience("https://domain.auth0.com")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .connectionScope("user_friends,email")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection_scope": "user_friends,email"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                var newDefaults = defaults
                newDefaults["connection_scope"] = "email"
                return [
                    "url": try! newWebAuth()
                        .connectionScope("user_friends")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection_scope": "user_friends"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                let organization = "foo"
                let invitation = "bar"
                let url = URL(string: "https://example.com?organization=\(organization)&invitation=\(invitation)")!
                return [
                    "url": try! newWebAuth()
                        .invitationURL(url)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": organization, "invitation": invitation]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLBehavior.self) {
                return [
                    "url": try! newWebAuth()
                        .authorizeURL(URL(string: "https://example.com/authorize")!)
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State),
                    "domain": "example.com",
                    "query": defaultQuery(),
                ]
            }

            context("encoding") {

                it("should encode + as %2B"){
                    let url = try! newWebAuth()
                            .parameters(["login_hint": "first+last@host.com"])
                            .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State)
                    expect(url.absoluteString.contains("first%2Blast@host.com")).to(beTrue())
                }

            }

            it("should build with a custom authorize url") {
                let url = URL(string: "https://example.com/authorize")!
                expect(newWebAuth().authorizeURL(url).overrideAuthorizeURL) == url
            }

            it("should handle buildAuthorizeURL errors") {
                let invitationUrl = URL(string: "https://example.com?invalid=query")!
                let webAuth = newWebAuth().invitationURL(invitationUrl) // Invalid invitation URL

                expect {
                    try webAuth.buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State)
                }.to(throwError { (error: WebAuthError) in
                    guard case .unknown(let message) = error.code else {
                        fail("Expected .unknown error, got \(error)")
                        return
                    }
                    expect(error.cause).to(beNil())
                    expect(message).to(contain("Invalid invitation URL"))
                })
            }

            it("should include dpop_jkt parameter when DPoP is enabled") {
                let webAuth = newWebAuth().useDPoP()
                let url = try webAuth.buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State)
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let dpopJktItem = components?.queryItems?.first { $0.name == "dpop_jkt" }

                expect(dpopJktItem?.value).toNot(beNil())
            }

            it("should not include dpop_jkt parameter when DPoP is not enabled") {
                let webAuth = newWebAuth()
                let url = try webAuth.buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, nonce: Nonce, state: State)
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let dpopJktItem = components?.queryItems?.first { $0.name == "dpop_jkt" }

                expect(dpopJktItem).to(beNil())
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

            context("state") {

                it("should generate a unique state on each access for the same auth object") {
                    let auth = newWebAuth()
                    expect(auth.state) != auth.state
                }

                it("should generate a unique state for different auth objects") {
                    expect(newWebAuth().state) != newWebAuth().state
                }

                it("should use a custom state value") {
                    let state = "foo"
                    expect(newWebAuth().state(state).state).to(equal(state))
                }

            }

            context("nonce") {

                it("should generate a default nonce") {
                    expect(newWebAuth().nonce).toNot(beEmpty())
                }

                it("should generate a unique nonce on each access for the same auth object") {
                    let auth = newWebAuth()
                    expect(auth.nonce) != auth.nonce
                }

                it("should generate a unique nonce for different auth objects") {
                    expect(newWebAuth().nonce) != newWebAuth().nonce
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
                auth = auth.provider({ url, _ in
                    isStarted = true
                    return SpyUserAgent()
                })
                auth.start { _ in }
                expect(isStarted).toEventually(beTrue())
            }

            it("should generate a state") {
                auth = auth.provider({ url, _ in SpyUserAgent() })
                auth.start { _ in }
                expect(auth.state).toNot(beNil())
            }

            it("should generate unique states for different auth objects") {
                expect(newWebAuth().state) != newWebAuth().state
            }

            it("should use the supplied state") {
                let state = UUID().uuidString
                auth = auth.state(state)
                expect(auth.state) == state
            }

            it("should use the state supplied via parameters") {
                let state = UUID().uuidString
                auth = auth.parameters(["state": state])
                expect(auth.state) == state
            }

            it("should generate a nonce") {
                auth = auth.provider({ url, _ in SpyUserAgent() })
                auth.start { _ in }
                expect(auth.nonce).toNot(beNil())
            }

            it("should use the supplied nonce") {
                let nonce = UUID().uuidString
                auth = auth.nonce(nonce)
                expect(auth.nonce) == nonce
            }

            it("should use the nonce supplied via parameters") {
                let nonce = UUID().uuidString
                auth = auth.parameters(["nonce": nonce])
                expect(auth.nonce) == nonce
            }

            it("should use the organization and invitation from the invitation URL") {
                let url = "https://\(Domain)?organization=foo&invitation=bar"
                var redirectURL: URL?
                auth = auth.invitationURL(URL(string: url)!).provider({ url, _ in
                    redirectURL = url
                    return SpyUserAgent()
                })
                auth.start { _ in }
                expect(redirectURL?.query).toEventually(contain("organization=foo"))
                expect(redirectURL?.query).toEventually(contain("invitation=bar"))
            }

            it("should produce an invalid invitation URL error when the organization is missing") {
                let url = "https://\(Domain)?invitation=foo"
                var result: WebAuthResult<Credentials>?
                auth = auth.invitationURL(URL(string: url)!)
                auth.start { result = $0 }
                expect(result).toEventually(haveUnknownError(containing: "Invalid invitation URL"))
            }

            it("should produce an invalid invitation URL error when the invitation is missing") {
                let url = "https://\(Domain)?organization=foo"
                var result: WebAuthResult<Credentials>?
                auth = auth.invitationURL(URL(string: url)!)
                auth.start { result = $0 }
                expect(result).toEventually(haveUnknownError(containing: "Invalid invitation URL"))
            }

            it("should produce an invalid invitation URL error when the organization and invitation are missing") {
                let url = "https://\(Domain)?foo=bar"
                var result: WebAuthResult<Credentials>?
                auth = auth.invitationURL(URL(string: url)!)
                auth.start { result = $0 }
                expect(result).toEventually(haveUnknownError(containing: "Invalid invitation URL"))
            }

            it("should produce an invalid invitation URL error when the query parameters are missing") {
                var result: WebAuthResult<Credentials>?
                auth = auth.invitationURL(DomainURL)
                auth.start { result = $0 }
                expect(result).toEventually(haveUnknownError(containing: "Invalid invitation URL"))
            }

            it("should produce a no bundle identifier error when redirect URL is missing") {
                var result: WebAuthResult<Credentials>?
                var noHostAuth = Auth0WebAuth(clientId: ClientId, url: URL(string: "https:")!, barrier: MockBarrier())
                noHostAuth.start { result = $0 }
                expect(result).toEventually(haveUnknownError(containing: "Unable to retrieve bundle identifier"))
            }

            context("transaction") {

                beforeEach {
                    TransactionStore.shared.clear()
                }

                it("should store a new transaction") {
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { _ in }
                    expect(TransactionStore.shared.current).toEventuallyNot(beNil())
                    TransactionStore.shared.cancel()
                }

                it("should cancel the current transaction") {
                    var result: WebAuthResult<Credentials>?
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { result = $0 }
                    expect(TransactionStore.shared.current).toEventuallyNot(beNil())
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
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { _ in }
                    auth.start { result = $0 }
                    expect(result).toEventually(haveWebAuthError(expectedError))
                }

                it("should lower the barrier") {
                    var firstResult: WebAuthResult<Credentials>?
                    var secondResult: WebAuthResult<Credentials>?
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.start { firstResult = $0 }
                    expect(TransactionStore.shared.current).toEventuallyNot(beNil())
                    TransactionStore.shared.cancel()
                    expect(firstResult).toEventually(haveWebAuthError(WebAuthError(code: .userCancelled)))
                    auth.start { secondResult = $0 }
                    expect(secondResult).toEventually(beNil())
                }

            }

        }

        // MARK: - Combine & Async/Await

        describe("Combine API") {
            var auth: Auth0WebAuth!
            var cancellables: Set<AnyCancellable>!
            
            beforeEach {
                let url = URL(string: "https://samples.auth0.com")!
                auth = Auth0WebAuth(clientId: "client123", url: url, auth0ClientInfo: Auth0ClientInfo())
                QueueBarrier.shared.lower()
                cancellables = []
            }
            
            afterEach {
                cancellables.removeAll()
            }
            
            it("start() publishes error on failure") {
                waitUntil { done in
                    auth.provider { url, completion in
                        completion(.failure(WebAuthError(code: .other)))
                        return SpyUserAgent()
                    }
                    .start()
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                expect(error.code).to(equal(.other))
                                done()
                            }
                        }, receiveValue: { _ in
                            fail("Should not emit credentials")
                        })
                        .store(in: &cancellables)
                }
            }

            it("logout() publishes completion on success") {
                waitUntil { done in
                    auth.provider { url, completion in
                        completion(.success(()))
                        return SpyUserAgent()
                    }
                    .logout(federated: false)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                fail("Unexpected error: \(error)")
                            }
                        }, receiveValue: {
                            done()
                        })
                        .store(in: &cancellables)
                }
            }

            it("logout() publishes error on failure") {
                waitUntil { done in
                    auth.provider { url, completion in
                        completion(.failure(WebAuthError(code: .other)))
                        return SpyUserAgent()
                    }
                    .logout(federated: false)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                expect(error.code).to(equal(.other))
                                done()
                            }
                        }, receiveValue: {
                            fail("Should not succeed")
                        })
                        .store(in: &cancellables)
                }
            }
        }

        describe("Async/Await API") {
            var auth: Auth0WebAuth!
            
            beforeEach {
                let url = URL(string: "https://samples.auth0.com")!
                QueueBarrier.shared.lower()
                auth = Auth0WebAuth(clientId: "client123", url: url, auth0ClientInfo: Auth0ClientInfo())
            }
            it("start() async throws on failure") {
                auth = auth.provider { url, completion in
                    completion(.failure(WebAuthError(code: .other)))
                    return SpyUserAgent()
                }

                waitUntil { done in
                    Task {
                        do {
                            _ = try await auth.start()
                            fail("Should have thrown an error")
                        } catch let error as WebAuthError {
                            expect(error.code).to(equal(.other))
                            done()
                        } catch {
                            fail("Unexpected error type")
                        }
                    }
                }
            }

            it("ignores double resume but still surfaces first error") {
                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        do {
                            _ = try await auth.provider { url, callback in
                                callback(.failure(WebAuthError(code: .userCancelled)))
                                // Second call -> ignored by continuation bridge
                                callback(.failure(WebAuthError(code: .userCancelled)))
                                return SpyUserAgent()
                            }.start()
                            fail("Expected error")
                        } catch let error as WebAuthError {
                            expect(error.code) == .userCancelled
                            done()
                        }
                    }
                }
            }

            it("logout() async completes on success") {
                auth = auth.provider { url, completion in
                    completion(.success(()))
                    return SpyUserAgent()
                }

                waitUntil { done in
                    Task {
                        do {
                            try await auth.logout(federated: false)
                            done()
                        } catch {
                            fail("Unexpected error: \(error)")
                        }
                    }
                }
            }

            it("logout() async throws on failure") {
                auth = auth.provider { url, completion in
                    completion(.failure(WebAuthError(code: .other)))
                    return SpyUserAgent()
                }
                
                waitUntil { done in
                    Task {
                        do {
                            try await auth.logout(federated: false)
                            fail("Should have thrown an error")
                        } catch let error as WebAuthError {
                            expect(error.code).to(equal(.other))
                            done()
                        } catch {
                            fail("Unexpected error type")
                        }
                    }
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
                auth = auth.provider({ url, _ in
                    isStarted = true
                    return SpyUserAgent()
                })
                auth.start { _ in }
                expect(isStarted).toEventually(beTrue())
            }

            it("should not include the federated parameter by default") {
                var redirectURL: URL?
                auth = auth.provider({ url, _ in
                    redirectURL = url
                    return SpyUserAgent()
                })
                auth.logout() { _ in }
                expect(redirectURL?.query?.contains("federated")).toEventually(beFalse())
            }

            it("should include the federated parameter") {
                var redirectURL: URL?
                auth = auth.provider({ url, _ in
                    redirectURL = url
                    return SpyUserAgent()
                })
                auth.logout(federated: true) { _ in }
                expect(redirectURL?.query?.contains("federated")).toEventually(beTrue())
            }

            it("should produce a no bundle identifier error when redirect URL is missing") {
                var result: WebAuthResult<Void>?
                var noHostAuth = Auth0WebAuth(clientId: ClientId, url: URL(string: "https:")!, barrier: MockBarrier())
                noHostAuth.logout() { result = $0 }
                expect(result).toEventually(haveUnknownError(containing: "Unable to retrieve bundle identifier"))
            }

            context("transaction") {

                var result: WebAuthResult<Void>?

                beforeEach {
                    result = nil
                    TransactionStore.shared.clear()
                }

                it("should store a new transaction") {
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.logout() { _ in }
                    expect(TransactionStore.shared.current).toEventuallyNot(beNil())
                }

                it("should cancel the current transaction") {
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.logout() { result = $0 }
                    expect(TransactionStore.shared.current).toEventuallyNot(beNil())
                    TransactionStore.shared.cancel()
                    expect(result).toEventually(haveWebAuthError(WebAuthError(code: .userCancelled)))
                    expect(TransactionStore.shared.current).to(beNil())
                }

                it("should resume the current transaction") {
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.logout() { result = $0 }
                    expect(TransactionStore.shared.current).toEventuallyNot(beNil())
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
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.logout { _ in }
                    auth.logout { result = $0 }
                    expect(result).toEventually(haveWebAuthError(expectedError))
                }

                it("should lower the barrier") {
                    var firstResult: WebAuthResult<Void>?
                    var secondResult: WebAuthResult<Void>?
                    auth = auth.provider({ url, callback in MockUserAgent(callback: callback) })
                    auth.logout { firstResult = $0 }
                    expect(TransactionStore.shared.current).toEventuallyNot(beNil())
                    TransactionStore.shared.cancel()
                    expect(firstResult).toEventually(haveWebAuthError(WebAuthError(code: .userCancelled)))
                    auth.logout { secondResult = $0 }
                    expect(secondResult).toEventually(beNil())
                }

            }

        }
        #endif

        describe("main thread callback execution") {

            it("should execute start() callback on main thread on failure") {
                let webAuth = newWebAuth()
                    .redirectURL(RedirectURL)
                    .provider { url, callback in
                        let agent = MockUserAgent(callback: callback)
                        DispatchQueue.global().async {
                            callback(.failure(WebAuthError(code: .userCancelled)))
                        }
                        return agent
                    }

                waitUntil(timeout: .seconds(2)) { done in
                    webAuth.start { result in
                        expect(Thread.isMainThread).to(beTrue())
                        done()
                    }
                }
            }

            it("should execute logout() callback on main thread") {
                let webAuth = newWebAuth()
                    .redirectURL(RedirectURL)
                    .provider { url, callback in
                        let agent = MockUserAgent(callback: callback)
                        DispatchQueue.global().async {
                            callback(.success(()))
                        }
                        return agent
                    }

                waitUntil(timeout: .seconds(2)) { done in
                    webAuth.logout(federated: false) { result in
                        expect(Thread.isMainThread).to(beTrue())
                        done()
                    }
                }
            }

        }

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
