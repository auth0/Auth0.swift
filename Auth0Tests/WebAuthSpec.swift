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
private let State = "state"

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

private func newWebAuth() -> Auth0WebAuth {
    return Auth0WebAuth(clientId: ClientId, url: DomainURL)
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
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .connection("facebook")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection": "facebook"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .scope("openid email")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["scope": "openid email"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                let state = UUID().uuidString
                return [
                    "url": newWebAuth()
                        .parameters(["state": state])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["state": state]),
                ]
            }

            it("should override default values") {
                let url = newWebAuth()
                    .parameters(["scope": "openid email phone"])
                    .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil)
                expect(url.a0_components?.queryItems).toNot(containItem(withName: "scope", value: "openid"))
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.idToken])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["response_type": "id_token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.token])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["response_type": "token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.idToken, .token])
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["response_type": "id_token token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.idToken])
                        .nonce("abc1234")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["nonce": "abc1234", "response_type" : "id_token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .responseType([.idToken])
                        .maxAge(10000) // 1 second
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["max_age": "10000", "response_type" : "id_token"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: "abc1234", invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": "abc1234"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: "abc1234", invitation: "xyz6789"),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["organization": "abc1234", "invitation": "xyz6789"]),
                    ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                var newDefaults = defaults
                newDefaults["audience"] = "https://wwww.google.com"
                return [
                    "url": newWebAuth()
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: State, organization: nil, invitation: nil),
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
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .audience("https://domain.auth0.com")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["audience": "https://domain.auth0.com"]),
                ]
            }

            itBehavesLike(ValidAuthorizeURLExample) {
                return [
                    "url": newWebAuth()
                        .connectionScope("user_friends,email")
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil),
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
                        .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: newDefaults, state: State, organization: nil, invitation: nil),
                    "domain": Domain,
                    "query": defaultQuery(withParameters: ["connection_scope": "user_friends"]),
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
            
            #if os(iOS)
            context("telemetry") {
                
                func getTelemetryInfoFromUrl(url: URL) -> [String: Any] {
                    let telemetry = (url.a0_components?.queryItems!.first(where: {$0.name == "auth0Client"})!.value)!!
                    let data = telemetry.a0_decodeBase64URLSafe()
                    let info = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                    return info
                }

                it("should include default telemetry"){
                    let url = newWebAuth()
                            .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil)

                    let info = getTelemetryInfoFromUrl(url: url)
                    let env = info["env"] as! [String : String]
                    expect(env["view"]) == MobileWebAuth.ViewASWebAuthenticationSession
                }

                it("should include telemetry for legacy auth"){
                    let url = newWebAuth()
                            .useLegacyAuthentication()
                            .buildAuthorizeURL(withRedirectURL: RedirectURL, defaults: defaults, state: State, organization: nil, invitation: nil)
                    let info = getTelemetryInfoFromUrl(url: url)
                    let env = info["env"] as! [String : String]
                    expect(env["view"]) == MobileWebAuth.ViewSFSafariViewController
                }
            }
            #endif
        }

        describe("redirect uri") {
            #if os(iOS)
            let platform = "ios"
            #else
            let platform = "macos"
            #endif

            it("should build with custom scheme") {
                let bundleId = Bundle.main.bundleIdentifier!
                expect(newWebAuth().redirectURL?.absoluteString) == "\(bundleId)://\(Domain)/\(platform)/\(bundleId)/callback"
            }

            it("should build with universal link") {
                let bundleId = Bundle.main.bundleIdentifier!
                expect(newWebAuth().useUniversalLink().redirectURL?.absoluteString) == "https://\(Domain)/\(platform)/\(bundleId)/callback"
            }

            it("should build with a custom url") {
                expect(newWebAuth().redirectURL(RedirectURL).redirectURL) == RedirectURL
            }

        }

        describe("other builder methods") {

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
                    expect(newWebAuth().issuer).to(equal("\(DomainURL.absoluteString)/"))
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

        }

        #if os(iOS)
        describe("session") {
            
            #if swift(>=5.1)
            context("before start") {
                
                it("should not use ephemeral session by default") {
                    expect(newWebAuth().ephemeralSession).to(beFalse())
                }

                it("should use ephemeral session") {
                    expect(newWebAuth().useEphemeralSession().ephemeralSession).to(beTrue())
                }

            }
            #endif

            context("after start") {

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

        }

        describe("safari") {

            var result: Result<Credentials>?

            beforeEach { result = nil }

            it("should build new controller") {
                expect(newWebAuth().newSafari(DomainURL, callback: {_ in}).0).toNot(beNil())
            }

            it("should fail if controller is not presented") {
                let callback = newWebAuth().newSafari(DomainURL, callback: { result = $0 }).1
                callback(.success(Credentials(json: ["access_token": "at", "token_type": "bearer"])))
                expect(result).toEventually(beFailure())
            }

            it("should fail if user dismissed safari viewcontroller") {
                let callback = newWebAuth().newSafari(DomainURL, callback: { result = $0 }).1
                callback(.failure(WebAuthError.userCancelled))
                expect(result).toEventually(beFailure())
            }
            
            it("should present a default presentation style") {
                let auth = newWebAuth().useLegacyAuthentication()
                let controller = auth.newSafari(DomainURL, callback: { _ in }).0
                expect(controller.modalPresentationStyle) == .fullScreen
            }
            
            it("should present user overridden presentation style") {
                let auth = newWebAuth().useLegacyAuthentication(withStyle: .overFullScreen)
                let controller = auth.newSafari(DomainURL, callback: { _ in }).0
                expect(controller.modalPresentationStyle) == .overFullScreen
            }
            
            if #available(iOS 11.0, *) {
                it("should present user with the .cancel dismiss button style") {
                    let auth = newWebAuth()
                        .useLegacyAuthentication(withStyle: .overFullScreen)
                    let controller = auth.newSafari(DomainURL, callback: { _ in }).0
                    
                    expect(controller.dismissButtonStyle) == .cancel
                }
            }
        }

        describe("logout") {

            context("ASWebAuthenticationSession") {

                var outcome: Bool?

                beforeEach {
                    outcome = nil
                    TransactionStore.shared.clear()
                }

                it("should launch AuthenticationServicesSessionCallback") {
                    guard #available(iOS 12.0, *) else { return }
                    let auth = newWebAuth()
                    auth.clearSession(federated: false) { _ in }
                    expect(TransactionStore.shared.current).toNot(beNil())
                }

                it("should cancel AuthenticationServicesSessionCallback") {
                    guard #available(iOS 12.0, *) else { return }
                    let auth = newWebAuth()
                    auth.clearSession(federated: false) { outcome = $0 }
                    TransactionStore.shared.cancel(TransactionStore.shared.current!)
                    expect(outcome).to(beFalse())
                    expect(TransactionStore.shared.current).to(beNil())
                }

                it("should resume AuthenticationServicesSessionCallback") {
                    guard #available(iOS 12.0, *) else { return }
                    let auth = newWebAuth()
                    auth.clearSession(federated: false) { outcome = $0 }
                    _ = TransactionStore.shared.resume(URL(string: "http://fake.com")!)
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
        #endif

    }

}
