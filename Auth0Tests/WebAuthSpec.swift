// WebAuthSpec.swift
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
import SafariServices

@testable import Auth0

private let ClientId = "ClientId"
private let Domain = "samples.auth0.com"
private let DomainURL = URL.a0_url(Domain)
private let RedirectURL = URL(string: "https://samples.auth0.com/callback")!

extension URL {
    var a0_components: URLComponents? {
        return URLComponents(url: self, resolvingAgainstBaseURL: true)
    }
}

private let ValidAuthorizeURLExample = "valid authorize url"
class WebAuthSharedExamplesConfiguration: QuickConfiguration {
    override class func configure(_ configuration: Configuration) {
        sharedExamples(ValidAuthorizeURLExample) { (context: SharedExampleContext) in
            let attrs = context()
            let url = attrs["url"] as! URL
            let params = attrs["query"] as! [String: String]
            let domain = attrs["domain"] as! String
            let components = url.a0_components

            it("should use domain \(domain)") {
                expect(components?.scheme) == "https"
                expect(components?.host) == domain
                expect(components?.path) == "/authorize"
            }

            it("should have state parameter") {
                expect(components?.queryItems).to(containItem(withName:"state"))
            }

            params.forEach { key, value in
                it("should have query parameter \(key)") {
                    expect(components?.queryItems).to(containItem(withName: key, value: value))
                }
            }
        }
    }
}

private func newWebAuth() -> SafariWebAuth {
    return SafariWebAuth(clientId: ClientId, url: DomainURL)
}

private func defaultQuery(withParameters parameters: [String: String] = [:]) -> [String: String] {
    var query = [
        "client_id": ClientId,
        "response_type": "code",
        "redirect_uri": RedirectURL.absoluteString,
        "scope": "openid",
        ]
    parameters.forEach { query[$0] = $1 }
    return query
}

private let defaults = ["response_type": "code"]

class WebAuthSpec: QuickSpec {

    override func spec() {

        describe("authorize URL") {

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .connection("facebook")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection": "facebook"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .scope("openid email")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["scope": "openid email"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                let state = UUID().uuidString
                return [
                    "url": newWebAuth()
                        .parameters(["state": state])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["state": state]),
                ]
            }

            it("should override default values") {
                let url = newWebAuth()
                    .parameters(["scope": "openid email phone"])
                    .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state")
                expect(url.a0_components?.queryItems).toNot(containItem(withName: "scope", value: "openid"))
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.idToken])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["response_type": "id_token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.token])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["response_type": "token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.idToken, .token])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["response_type": "id_token token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.idToken])
                        .nonce("abc1234")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["nonce": "abc1234", "response_type" : "id_token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                var newDefaults = defaults
                newDefaults["audience"] = "https://wwww.google.com"
                return [
                    "url": newWebAuth().buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://wwww.google.com"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                var newDefaults = defaults
                newDefaults["audience"] = "https://wwww.google.com"
                return [
                    "url": newWebAuth()
                        .audience("https://domain.auth0.com")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .audience("https://domain.auth0.com")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .connectionScope("user_friends,email")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection_scope": "user_friends,email"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                var newDefaults = defaults
                newDefaults["connection_scope"] = "email"
                return [
                    "url": newWebAuth()
                        .connectionScope("user_friends")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: "state"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection_scope": "user_friends"]),
                ]
            }

        }

        describe("redirect uri") {

            it("should build with custom scheme") {
                let bundleId = Bundle.main.bundleIdentifier!
                expect(newWebAuth().redirectURL?.absoluteString) == "\(bundleId)://\(Domain)/ios/\(bundleId)/callback"
            }

            it("should build with universal link") {
                let bundleId = Bundle.main.bundleIdentifier!
                expect(newWebAuth().useUniversalLink().redirectURL?.absoluteString) == "https://\(Domain)/ios/\(bundleId)/callback"
            }

        }


        describe("session") {
            let storage = TransactionStore.shared

            beforeEach {
                if let current = storage.current {
                    storage.cancel(current)
                }
            }

            it("should save started session") {
                newWebAuth().start({ _ in})
                expect(storage.current).toNot(beNil())
            }

            it("should hava a generated state") {
                let auth = newWebAuth()
                auth.start({ _ in})
                expect(storage.current?.state).toNot(beNil())
            }

            it("should honor supplied state") {
                let state = UUID().uuidString
                newWebAuth().state(state).start({ _ in})
                expect(storage.current?.state) == state
            }

            it("should honor supplied state via parameters") {
                let state = UUID().uuidString
                newWebAuth().parameters(["state": state]).start({ _ in})
                expect(storage.current?.state) == state
            }

            it("should generate different state on every start") {
                let auth = newWebAuth()
                auth.start({ _ in})
                let state = storage.current?.state
                auth.start({ _ in})
                expect(storage.current?.state) != state
            }

        }

        describe("safari") {

            var result: Result<Credentials>?

            beforeEach { result = nil }

            it("should build new controller") {
                expect(newWebAuth().newSafari(DomainURL, callback: {_ in}).0).toNot(beNil())
            }

            it("should fail if controller is not presented") {
                let callback = newWebAuth().newSafari(DomainURL, callback: { result = $0 }).1
                callback(.success(result: Credentials(json: ["access_token": "at", "token_type": "bearer"])))
                expect(result).toEventually(beFailure())
            }

            it("should fail if user dismissed safari viewcontroller") {
                let callback = newWebAuth().newSafari(DomainURL, callback: { result = $0 }).1
                callback(.failure(error: WebAuthError.userCancelled))
                expect(result).toEventually(beFailure())
            }
        }

        describe("logout") {

            context("SFAuthenticationSession") {

                var outcome: Bool?

                beforeEach {
                    outcome = nil
                    TransactionStore.shared.clear()
                }

                it("should launch SafariAuthenticationSessionCallback") {
                    let auth = newWebAuth()
                    auth.clearSession(federated: false) { _ in }
                    expect(TransactionStore.shared.current).toNot(beNil())
                }

                it("should cancel SafariAuthenticationSessionCallback") {
                    let auth = newWebAuth()
                    auth.clearSession(federated: false) { outcome = $0 }
                    TransactionStore.shared.cancel(TransactionStore.shared.current!)
                    expect(outcome).to(beFalse())
                    expect(TransactionStore.shared.current).to(beNil())
                }

                it("should resume SafariAuthenticationSessionCallback") {
                    let auth = newWebAuth()
                    auth.clearSession(federated: false) { outcome = $0 }
                    _ = TransactionStore.shared.resume(URL(string: "http://fake.com")!, options: [:])
                    expect(outcome).to(beTrue())
                    expect(TransactionStore.shared.current).to(beNil())
                }

            }

            context("SFSafariViewController") {

                it("should launch silent safari viewcontroller") {
                    let auth = newWebAuth()
                    _ = auth.useLegacyAuthentication()
                    auth.clearSession(federated: false) { _ in }
                    expect(auth.presenter.topViewController is SilentSafariViewController).toNot(beNil())
                }

            }
        }

    }

}

func containItem(withName name: String, value: String? = nil) -> Predicate<[URLQueryItem]> {
    return Predicate<[URLQueryItem]>.define("contain item with name <\(name)>") { expression, failureMessage -> PredicateResult in
        guard let items = try expression.evaluate() else { return PredicateResult(status: .doesNotMatch, message: failureMessage) }
        let outcome = items.contains { item -> Bool in
            return item.name == name && ((value == nil && item.value != nil) || item.value == value)
        }
        return PredicateResult(bool: outcome, message: failureMessage)
    }
}
