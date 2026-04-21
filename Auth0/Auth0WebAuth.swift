#if WEB_AUTH_PLATFORM
import Foundation
import Combine
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct Auth0WebAuth: WebAuth, Sendable {

    let clientId: String
    let url: URL
    let session: URLSession
    let storage: TransactionStore

    var auth0ClientInfo: Auth0ClientInfo
    let barrier: Barrier
    var logger: Logger?
    var dpop: DPoP?

    #if os(macOS)
    private let platform = "macos"
    #elseif os(iOS)
    private let platform = "ios"
    #else
    private let platform = "visionos"
    #endif
    private let responseType = "code"

    private(set) var parameters: [String: String] = [:]
    private(set) var headers: [String: String] = [:]
    private(set) var https = false
    private(set) var ephemeralSession = false
    private(set) var issuer: String
    private(set) var leeway: Int = 60 * 1000 // Default leeway is 60 seconds
    private(set) var maxAge: Int?
    private(set) var organization: String?
    private(set) var invitationURL: URL?
    private(set) var overrideAuthorizeURL: URL?
    private(set) var provider: WebAuthProvider?
    private(set) var onCloseCallback: (@Sendable @MainActor () -> Void)?
    private(set) var presentationWindow: Auth0WindowRepresentable?
    private var _credentialsManager: CredentialsManager?

    private var _redirectURL: URL?

    var redirectURL: URL? {
        get { _redirectURL ?? computeDefaultRedirectURL() }
        set { _redirectURL = newValue }
    }

    var credentialsManager: CredentialsManager? {
        return _credentialsManager
    }

    var state: String {
        return parameters["state"] ?? generateRandomString()
    }

    var nonce: String {
        return parameters["nonce"] ?? generateRandomString()
    }

    init(clientId: String,
         url: URL,
         session: URLSession = URLSession.shared,
         storage: TransactionStore = TransactionStore.shared,
         auth0ClientInfo: Auth0ClientInfo = Auth0ClientInfo(),
         barrier: Barrier = QueueBarrier.shared) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.storage = storage
        self.auth0ClientInfo = auth0ClientInfo
        self.barrier = barrier
        self.issuer = url.absoluteString
    }

    func connection(_ connection: String) -> Self {
        var copy = self
        copy.parameters["connection"] = connection
        return copy
    }

    func scope(_ scope: String) -> Self {
        var copy = self
        copy.parameters["scope"] = scope
        return copy
    }

    func connectionScope(_ connectionScope: String) -> Self {
        var copy = self
        copy.parameters["connection_scope"] = connectionScope
        return copy
    }

    func nonce(_ nonce: String) -> Self {
        var copy = self
        copy.parameters["nonce"] = nonce
        return copy
    }

    func state(_ state: String) -> Self {
        var copy = self
        copy.parameters["state"] = state
        return copy
    }

    func parameters(_ parameters: [String: String]) -> Self {
        var copy = self
        parameters.forEach { copy.parameters[$0] = $1 }
        return copy
    }

    @available(iOS 17.4, macOS 14.4, visionOS 1.2, *)
    func headers(_ headers: [String: String]) -> Self {
        var copy = self
        headers.forEach { copy.headers[$0] = $1 }
        return copy
    }

    func redirectURL(_ redirectURL: URL) -> Self {
        var copy = self
        copy._redirectURL = redirectURL
        return copy
    }

    func authorizeURL(_ authorizeURL: URL) -> Self {
        var copy = self
        copy.overrideAuthorizeURL = authorizeURL
        return copy
    }

    func audience(_ audience: String) -> Self {
        var copy = self
        copy.parameters["audience"] = audience
        return copy
    }

    func issuer(_ issuer: String) -> Self {
        var copy = self
        copy.issuer = issuer
        return copy
    }

    func leeway(_ leeway: Int) -> Self {
        var copy = self
        copy.leeway = leeway
        return copy
    }

    func maxAge(_ maxAge: Int) -> Self {
        var copy = self
        copy.maxAge = maxAge
        return copy
    }

    func useHTTPS() -> Self {
        var copy = self
        copy.https = true
        return copy
    }

    func useEphemeralSession() -> Self {
        var copy = self
        copy.ephemeralSession = true
        return copy
    }

    func invitationURL(_ invitationURL: URL) -> Self {
        var copy = self
        copy.invitationURL = invitationURL
        return copy
    }

    func organization(_ organization: String) -> Self {
        var copy = self
        copy.organization = organization
        return copy
    }

    func provider(_ provider: @escaping WebAuthProvider) -> Self {
        var copy = self
        copy.provider = provider
        return copy
    }

    func onClose(_ callback: (@Sendable () -> Void)?) -> Self {
        var copy = self
        copy.onCloseCallback = callback
        return copy
    }

    func presentationWindow(_ window: Auth0WindowRepresentable) -> Self {
        var copy = self
        copy.presentationWindow = window
        return copy
    }

    func start(_ callback: @escaping @Sendable @MainActor (WebAuthResult<Credentials>) -> Void) {
        Task { @MainActor in
            self._start(callback)
        }
    }

    func useCredentialsManager(_ credentialsManager: CredentialsManager) -> Self {
        var copy = self
        copy._credentialsManager = credentialsManager
        return copy
    }

    @MainActor
    private func _start(_ callback: @escaping @Sendable @MainActor (WebAuthResult<Credentials>) -> Void) {
        guard barrier.raise() else {
            return callback(.failure(WebAuthError(code: .transactionActiveAlready)))
        }

        guard let redirectURL = self.redirectURL else {
            return callback(.failure(WebAuthError(code: .unknown("Unable to retrieve bundle identifier"))))
        }

        let nonce = nonce
        let state = state
        let handler = self.handler(redirectURL, nonce: nonce)

        let authorizeURL: URL
        do {
            authorizeURL = try self.buildAuthorizeURL(withRedirectURL: redirectURL,
                                                      defaults: handler.defaults,
                                                      nonce: nonce,
                                                      state: state)
        } catch {
            return callback(.failure(error))
        }

        let credentialsManager = self.credentialsManager
        let storingCallback: @MainActor @Sendable (WebAuthResult<Credentials>) -> Void = { result in
            if case .success(let credentials) = result, let cm = credentialsManager {
                do {
                    try cm.store(credentials: credentials)
                } catch {
                    return callback(.failure(WebAuthError(code: .credentialsManagerError, cause: error)))
                }
            }
            callback(result)
        }

        let provider = self.provider ?? WebAuthentication.asProvider(redirectURL: redirectURL,
                                                                     ephemeralSession: ephemeralSession,
                                                                     headers: headers,
                                                                     presentationWindow: self.presentationWindow)
        let closeCallback = onCloseCallback
        let userAgent = provider(authorizeURL) { [storage, barrier] result in
            storage.clear()
            barrier.lower()

            switch result {
            case .success:
                if let closeCallback {
                    Task { @MainActor in closeCallback() }
                }
            case .failure(let error):
                Task { @MainActor in storingCallback(.failure(error)) }
            }
        }
        let transaction = LoginTransaction(redirectURL: redirectURL,
                                           state: state,
                                           userAgent: userAgent,
                                           handler: handler,
                                           logger: self.logger,
                                           callback: storingCallback)
        self.storage.store(transaction)
        userAgent.start()
        logger?.trace(url: authorizeURL, source: String(describing: userAgent.self))
    }

    func logout(federated: Bool, callback: @escaping @Sendable @MainActor (WebAuthResult<Void>) -> Void) {
        Task { @MainActor in self._logout(federated: federated, callback: callback) }
    }

    @MainActor
    private func _logout(federated: Bool, callback: @escaping @Sendable @MainActor (WebAuthResult<Void>) -> Void) {
        guard barrier.raise() else {
            return callback(.failure(WebAuthError(code: .transactionActiveAlready)))
        }

        let endpoint = federated ?
            URL(string: "v2/logout?federated", relativeTo: self.url)! :
            URL(string: "v2/logout", relativeTo: self.url)!
        let returnTo = URLQueryItem(name: "returnTo", value: self.redirectURL?.absoluteString)
        let clientId = URLQueryItem(name: "client_id", value: self.clientId)
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems ?? []
        components?.queryItems = queryItems + [returnTo, clientId]

        guard let logoutURL = components?.url, let redirectURL = self.redirectURL else {
            return callback(.failure(WebAuthError(code: .unknown("Unable to retrieve bundle identifier"))))
        }

        let credentialsManager = self.credentialsManager
        let clearingCallback: @MainActor @Sendable (WebAuthResult<Void>) -> Void = { result in
            if case .success = result, let cm = credentialsManager {
                do {
                    try cm.clear()
                } catch {
                    return callback(.failure(WebAuthError(code: .credentialsManagerError, cause: error)))
                }
            }
            callback(result)
        }

        let provider = self.provider ?? WebAuthentication.asProvider(redirectURL: redirectURL,
                                                                     headers: headers,
                                                                     presentationWindow: self.presentationWindow)
        let userAgent = provider(logoutURL) { [storage, barrier] result in
            storage.clear()
            barrier.lower()
            Task { @MainActor in clearingCallback(result) }
        }
        let transaction = LogoutTransaction(userAgent: userAgent)
        self.storage.store(transaction)
        userAgent.start()
    }

    func buildAuthorizeURL(withRedirectURL redirectURL: URL,
                           defaults: [String: String],
                           nonce: String,
                           state: String) throws(WebAuthError) -> URL {
        guard let authorize = self.overrideAuthorizeURL ?? URL(string: "authorize", relativeTo: self.url),
              var components = URLComponents(url: authorize, resolvingAgainstBaseURL: true) else {
            let message = "Unable to build authorize URL with base URL: \(self.url.absoluteString)."
            throw WebAuthError(code: .unknown(message))
        }

        var items: [URLQueryItem] = []
        var entries = defaults

        entries["scope"] = defaultScope
        entries["client_id"] = self.clientId
        entries["response_type"] = self.responseType
        entries["redirect_uri"] = redirectURL.absoluteString
        entries["state"] = state
        entries["nonce"] = nonce
        entries["organization"] = self.organization

        if let invitationURL = self.invitationURL {
            guard let queryItems = URLComponents(url: invitationURL, resolvingAgainstBaseURL: false)?.queryItems,
                  let organizationId = queryItems.first(where: { $0.name == "organization" })?.value,
                  let invitationId = queryItems.first(where: { $0.name == "invitation" })?.value else {
                throw WebAuthError(code: .unknown("Invalid invitation URL: missing organization or invitation parameters"))
            }

            entries["organization"] = organizationId
            entries["invitation"] = invitationId
        }

        if let maxAge = self.maxAge {
            entries["max_age"] = String(maxAge)
        }

        do {
            entries["dpop_jkt"] = try dpop?.jkt() // This creates a new key pair if one is not already stored
        } catch {
            throw WebAuthError(code: .other, cause: error)
        }

        self.parameters.forEach { entries[$0] = $1 }

        entries["scope"] = includeRequiredScope(in: entries["scope"])
        entries.forEach { items.append(URLQueryItem(name: $0, value: $1)) }
        components.queryItems = self.auth0ClientInfo.queryItemsWithTelemetry(queryItems: items)
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url!
    }

    func generateRandomString() -> String {
        let data = Data(count: 32)
        var tempData = data
        let result = tempData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, data.count, $0.baseAddress!)
        }
        guard result == errSecSuccess, let randomString = tempData.a0_encodeBase64URLSafe()
        else { return UUID().uuidString.replacingOccurrences(of: "-", with: "") }
        return randomString
    }

    private func computeDefaultRedirectURL() -> URL? {
        guard let bundleID = Bundle.main.bundleIdentifier, let domain = self.url.host else { return nil }
        let scheme: String

        if #available(iOS 17.4, macOS 14.4, *) {
            scheme = https ? "https" : bundleID
        } else {
            scheme = bundleID
        }

        guard let baseURL = URL(string: "\(scheme)://\(domain)") else { return nil }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)

        return components?.url?
            .appendingPathComponent(self.url.path)
            .appendingPathComponent(self.platform)
            .appendingPathComponent(bundleID)
            .appendingPathComponent("callback")
    }

    private func handler(_ redirectURL: URL, nonce: String) -> OAuth2Grant {
        var authentication = Auth0Authentication(clientId: self.clientId,
                                                 url: self.url,
                                                 session: self.session,
                                                 auth0ClientInfo: self.auth0ClientInfo)
        authentication.dpop = self.dpop
        authentication.logger = self.logger
        return PKCE(authentication: authentication,
                    redirectURL: redirectURL,
                    issuer: self.issuer,
                    leeway: self.leeway,
                    maxAge: self.maxAge,
                    nonce: nonce,
                    organization: self.organization)
    }

}

// MARK: - Combine

extension Auth0WebAuth {

    public func start() -> AnyPublisher<Credentials, WebAuthError> {
        Deferred {
            Future { promise in
                let box = SendableBox(value: promise)
                self.start { result in
                    box.value(result)
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func logout(federated: Bool) -> AnyPublisher<Void, WebAuthError> {
        return Deferred {
            Future { callback in
                let box = SendableBox(value: callback)
                self.logout(federated: federated) { result in
                    box.value(result)
                }
            }
        }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if canImport(_Concurrency)
extension Auth0WebAuth {

    @MainActor
    func start() async throws -> Credentials {
        var alreadyResumed = false
        return try await withCheckedThrowingContinuation { continuation in
            self.start { result in
                guard !alreadyResumed else { return }
                alreadyResumed = true
                continuation.resume(with: result)
            }
        }
    }

    @MainActor
    func logout(federated: Bool) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.logout(federated: federated) { result in
                continuation.resume(with: result)
            }
        }
    }

}
#endif
#endif
