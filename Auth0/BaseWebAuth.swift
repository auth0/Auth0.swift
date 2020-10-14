// BaseWebAuth.swift
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

#if WEB_AUTH_PLATFORM
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

class BaseWebAuth: WebAuthenticatable {

    let clientId: String
    let url: URL
    let storage: TransactionStore
    var telemetry: Telemetry
    var logger: Logger?
    var universalLink = false
    var ephemeralSession = false

    private let platform: String
    private(set) var parameters: [String: String] = [:]
    private(set) var issuer: String
    private(set) var leeway: Int = 60 * 1000 // Default leeway is 60 seconds
    private var responseType: [ResponseType] = [.code]
    private var nonce: String?
    private var maxAge: Int?

    lazy var redirectURL: URL? = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
        var components = URLComponents(url: self.url, resolvingAgainstBaseURL: true)
        components?.scheme = self.universalLink ? "https" : bundleIdentifier
        return components?.url?
            .appendingPathComponent(self.platform)
            .appendingPathComponent(bundleIdentifier)
            .appendingPathComponent("callback")
    }()

    init(platform: String, clientId: String, url: URL, storage: TransactionStore, telemetry: Telemetry) {
        self.platform = platform
        self.clientId = clientId
        self.url = url
        self.storage = storage
        self.telemetry = telemetry
        self.issuer = "\(url.absoluteString)/"
    }

    func useUniversalLink() -> Self {
        self.universalLink = true
        return self
    }

    func connection(_ connection: String) -> Self {
        self.parameters["connection"] = connection
        return self
    }

    func scope(_ scope: String) -> Self {
        self.parameters["scope"] = scope
        return self
    }

    func connectionScope(_ connectionScope: String) -> Self {
        self.parameters["connection_scope"] = connectionScope
        return self
    }

    func state(_ state: String) -> Self {
        self.parameters["state"] = state
        return self
    }

    func parameters(_ parameters: [String: String]) -> Self {
        parameters.forEach { self.parameters[$0] = $1 }
        return self
    }

    func responseType(_ responseType: [ResponseType]) -> Self {
        self.responseType = responseType
        return self
    }

    func redirectURL(_ redirectURL: URL) -> Self {
        self.redirectURL = redirectURL
        return self
    }

    func nonce(_ nonce: String) -> Self {
        self.nonce = nonce
        return self
    }

    func usingImplicitGrant() -> Self {
        return self.responseType([.token])
    }

    func audience(_ audience: String) -> Self {
        self.parameters["audience"] = audience
        return self
    }

    func issuer(_ issuer: String) -> Self {
        self.issuer = issuer
        return self
    }

    func leeway(_ leeway: Int) -> Self {
        self.leeway = leeway
        return self
    }

    func maxAge(_ maxAge: Int) -> Self {
        self.maxAge = maxAge
        return self
    }

    #if swift(>=5.1)
    func useEphemeralSession() -> Self {
        self.ephemeralSession = true
        return self
    }
    #endif

    func start(_ callback: @escaping (Result<Credentials>) -> Void) {
        guard let redirectURL = self.redirectURL else {
            return callback(Result.failure(error: WebAuthError.noBundleIdentifierFound))
        }
        if self.responseType.contains(.idToken) {
            guard self.nonce != nil else { return callback(Result.failure(error: WebAuthError.noNonceProvided)) }
        }
        let handler = self.handler(redirectURL)
        let state = self.parameters["state"] ?? generateDefaultState()
        let authorizeURL = self.buildAuthorizeURL(withRedirectURL: redirectURL,
                                                  defaults: handler.defaults,
                                                  state: state)

        // performLogin must handle the callback
        if let session = performLogin(authorizeURL: authorizeURL,
                                      redirectURL: redirectURL,
                                      state: state,
                                      handler: handler,
                                      callback: callback) {
            logger?.trace(url: authorizeURL, source: String(describing: session.self))
            self.storage.store(session)
        }
    }

    func performLogin(authorizeURL: URL,
                      redirectURL: URL,
                      state: String?,
                      handler: OAuth2Grant,
                      callback: @escaping (Result<Credentials>) -> Void) -> AuthTransaction? {
        #if canImport(AuthenticationServices)
        if #available(iOS 12.0, macOS 10.15, *) {
            return AuthenticationServicesSession(authorizeURL: authorizeURL,
                                                 redirectURL: redirectURL,
                                                 state: state,
                                                 handler: handler,
                                                 logger: self.logger,
                                                 ephemeralSession: self.ephemeralSession,
                                                 callback: callback)
        }
        #endif
        // TODO: On the next major add a new case to WebAuthError
        callback(.failure(error: WebAuthError.unknownError))
        return nil
    }

    func clearSession(federated: Bool, callback: @escaping (Bool) -> Void) {
        let endpoint = federated ?
            URL(string: "/v2/logout?federated", relativeTo: self.url)! :
            URL(string: "/v2/logout", relativeTo: self.url)!

        let returnTo = URLQueryItem(name: "returnTo", value: self.redirectURL?.absoluteString)
        let clientId = URLQueryItem(name: "client_id", value: self.clientId)
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems ?? []
        components?.queryItems = queryItems + [returnTo, clientId]

        guard let logoutURL = components?.url, let redirectURL = self.redirectURL else {
            return callback(false)
        }

        // performLogout must handle the callback
        if let session = performLogout(logoutURL: logoutURL,
                                       redirectURL: redirectURL,
                                       federated: federated,
                                       callback: callback) {
            self.storage.store(session)
        }
    }

    func performLogout(logoutURL: URL,
                       redirectURL: URL,
                       federated: Bool,
                       callback: @escaping (Bool) -> Void) -> AuthTransaction? {
        #if canImport(AuthenticationServices)
        if #available(iOS 12.0, macOS 10.15, *) {
            return AuthenticationServicesSessionCallback(url: logoutURL,
                                                         schemeURL: redirectURL,
                                                         callback: callback)
        }
        #endif
        callback(false)
        return nil
    }

    func buildAuthorizeURL(withRedirectURL redirectURL: URL, defaults: [String: String], state: String?) -> URL {
        let authorize = URL(string: "/authorize", relativeTo: self.url)!
        var components = URLComponents(url: authorize, resolvingAgainstBaseURL: true)!
        var items: [URLQueryItem] = []
        var entries = defaults
        entries["client_id"] = self.clientId
        entries["redirect_uri"] = redirectURL.absoluteString
        entries["scope"] = "openid"
        entries["state"] = state
        entries["response_type"] = self.responseType.map { $0.label! }.joined(separator: " ")
        if self.responseType.contains(.idToken) {
            entries["nonce"] = self.nonce
            if let maxAge = self.maxAge {
                entries["max_age"] = String(maxAge)
            }
        }

        self.parameters.forEach { entries[$0] = $1 }

        entries.forEach { items.append(URLQueryItem(name: $0, value: $1)) }
        components.queryItems = self.telemetry.queryItemsWithTelemetry(queryItems: items)
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url!
    }

    private func handler(_ redirectURL: URL) -> OAuth2Grant {
        var authentication = Auth0Authentication(clientId: self.clientId, url: self.url, telemetry: self.telemetry)
        if self.responseType.contains([.code]) { // both Hybrid and Code flow
            authentication.logger = self.logger
            return PKCE(authentication: authentication,
                        redirectURL: redirectURL,
                        responseType: self.responseType,
                        issuer: self.issuer,
                        leeway: self.leeway,
                        maxAge: self.maxAge,
                        nonce: self.nonce)
        }
        return ImplicitGrant(authentication: authentication,
                             responseType: self.responseType,
                             issuer: self.issuer,
                             leeway: self.leeway,
                             maxAge: self.maxAge,
                             nonce: self.nonce)
    }

    func generateDefaultState() -> String? {
        let data = Data(count: 32)
        var tempData = data

        let result = tempData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, data.count, $0.baseAddress!)
        }

        guard result == 0 else { return nil }
        return tempData.a0_encodeBase64URLSafe()
    }

}

extension Auth0Authentication {

    func webAuth(withConnection connection: String) -> WebAuth {
        let webAuth = Auth0WebAuth(clientId: self.clientId, url: self.url, telemetry: self.telemetry)
        return webAuth
            .logging(enabled: self.logger != nil)
            .connection(connection)
    }

}
#endif
