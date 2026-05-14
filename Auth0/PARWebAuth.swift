#if WEB_AUTH_PLATFORM
import Foundation
import Combine

/// Handles the browser authorization step of a PAR (Pushed Authorization Request) flow.
///
/// Opens the `/authorize` endpoint with a `request_uri` obtained from your backend's PAR endpoint call,
/// and returns the authorization code for your backend to exchange for tokens.
///
/// Auth0 only supports PAR for **confidential clients**. Since mobile apps are public clients,
/// the `/oauth/par` and `/oauth/token` calls must be made by your backend (BFF - Backend for Frontend).
/// The SDK only handles opening the browser with the `request_uri` and returning the resulting authorization code.
///
/// Your Auth0 application configured in the SDK should use the **same client_id** as the one your backend
/// uses when calling the `/oauth/par` endpoint.
///
/// ## Usage
///
/// ```swift
/// let authCode = try await Auth0
///     .authorizeWithRequestUri(clientId: "YOUR_CLIENT_ID", domain: "YOUR_DOMAIN")
///     .sessionTransferToken(token)
///     .start(requestUri: requestUri)
/// // Send authCode.code to your BFF for token exchange
/// ```
///
/// ## See Also
///
/// - ``AuthorizationCode``
/// - ``WebAuthError``
public class PARWebAuth {

    let clientId: String
    let url: URL
    private let storage: TransactionStore
    private let barrier: Barrier

    private var sessionTransferTokenValue: String?
    private var customProvider: WebAuthProvider?
    private var ephemeralSession = false

    lazy var redirectURL: URL? = {
        guard let bundleID = Bundle.main.bundleIdentifier, let domain = self.url.host else { return nil }
        let scheme = bundleID
        guard let baseURL = URL(string: "\(scheme)://\(domain)") else { return nil }

        #if os(macOS)
        let platform = "macos"
        #elseif os(iOS)
        let platform = "ios"
        #else
        let platform = "visionos"
        #endif

        return baseURL
            .appendingPathComponent(self.url.path)
            .appendingPathComponent(platform)
            .appendingPathComponent(bundleID)
            .appendingPathComponent("callback")
    }()

    /// Creates a new `PARWebAuth` instance.
    ///
    /// - Parameters:
    ///   - clientId: The Auth0 client ID.
    ///   - url: The Auth0 domain URL.
    public init(clientId: String, url: URL) {
        self.clientId = clientId
        self.url = url
        self.storage = TransactionStore.shared
        self.barrier = QueueBarrier.shared
    }

    init(clientId: String,
         url: URL,
         storage: TransactionStore,
         barrier: Barrier) {
        self.clientId = clientId
        self.url = url
        self.storage = storage
        self.barrier = barrier
    }

    // MARK: - Builder Methods

    /// Provide a session transfer token to be passed as a query parameter to the `/authorize` endpoint.
    /// This enables web single sign-on by transferring an existing session to the browser.
    ///
    /// - Parameter token: The session transfer token obtained from ``Authentication/ssoExchange(refreshToken:parameters:headers:)``.
    /// - Returns: The same `PARWebAuth` instance to allow method chaining.
    public func sessionTransferToken(_ token: String) -> Self {
        self.sessionTransferTokenValue = token
        return self
    }

    /// Specify a custom ``WebAuthProvider`` to handle the browser session.
    ///
    /// - Parameter provider: A custom provider.
    /// - Returns: The same `PARWebAuth` instance to allow method chaining.
    public func provider(_ provider: @escaping WebAuthProvider) -> Self {
        self.customProvider = provider
        return self
    }

    /// Use a private browser session to avoid storing the session cookie in the shared cookie jar.
    ///
    /// - Returns: The same `PARWebAuth` instance to allow method chaining.
    public func useEphemeralSession() -> Self {
        self.ephemeralSession = true
        return self
    }

    // MARK: - Start (Callback)

    /// Start the PAR authorization flow using a `request_uri` from a PAR response.
    /// Opens the browser with the authorize URL and returns the authorization code
    /// for the app to exchange via BFF.
    ///
    /// - Parameters:
    ///   - requestUri: The `request_uri` obtained from the PAR endpoint (must start with `urn:ietf:params:oauth:request_uri:`).
    ///   - callback: Callback with the authorization code result.
    public func start(requestUri: String, callback: @escaping (WebAuthResult<AuthorizationCode>) -> Void) {
        guard barrier.raise() else {
            return callback(.failure(WebAuthError(code: .transactionActiveAlready)))
        }

        guard PARUtils.isValidRequestUri(requestUri) else {
            barrier.lower()
            return callback(.failure(WebAuthError(code: .invalidRequestUri(requestUri))))
        }

        guard let redirectURL = self.redirectURL else {
            barrier.lower()
            return callback(.failure(WebAuthError(code: .noBundleIdentifier)))
        }

        var additionalParameters: [String: String] = [:]
        if let sst = sessionTransferTokenValue {
            additionalParameters["session_transfer_token"] = sst
        }

        let authorizeURL = PARUtils.buildAuthorizeURL(
            baseURL: url,
            clientId: clientId,
            requestUri: requestUri,
            additionalParameters: additionalParameters
        )

        let provider = self.customProvider ?? WebAuthentication.asProvider(
            redirectURL: redirectURL,
            ephemeralSession: ephemeralSession
        )

        let userAgent = provider(authorizeURL) { [storage, barrier] result in
            storage.clear()
            barrier.lower()

            switch result {
            case .success:
                break // Transaction will handle the callback
            case .failure(let error):
                callback(.failure(error))
            }
        }

        let transaction = PARTransaction(
            redirectURL: redirectURL,
            userAgent: userAgent,
            callback: callback
        )

        self.storage.store(transaction)
        userAgent.start()
    }

}

// MARK: - Combine

public extension PARWebAuth {

    /// Start the PAR authorization flow as a Combine publisher.
    ///
    /// - Parameter requestUri: The `request_uri` obtained from the PAR endpoint.
    /// - Returns: A publisher that emits an ``AuthorizationCode`` or a ``WebAuthError``.
    func start(requestUri: String) -> AnyPublisher<AuthorizationCode, WebAuthError> {
        return Deferred {
            Future { [weak self] callback in
                self?.start(requestUri: requestUri, callback: callback)
            }
        }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if canImport(_Concurrency)
public extension PARWebAuth {

    /// Start the PAR authorization flow using async/await.
    ///
    /// - Parameter requestUri: The `request_uri` obtained from the PAR endpoint.
    /// - Returns: An ``AuthorizationCode`` containing the authorization code.
    /// - Throws: A ``WebAuthError`` if the operation fails.
    func start(requestUri: String) async throws -> AuthorizationCode {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                self.start(requestUri: requestUri) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

}
#endif
#endif
