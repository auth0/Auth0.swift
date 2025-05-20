import Foundation

// MARK: - Factory Methods

public func myAccount(token: String, domain: String, session: URLSession = .shared) -> MyAccount {
    return Auth0MyAccount(token: token, url: .httpsURL(from: domain), session: session)
}

public func myAccount(token: String, session: URLSession = .shared, bundle: Bundle = .main) -> MyAccount {
    let values = plistValues(bundle: bundle)!
    return myAccount(token: token, domain: values.domain, session: session)
}

// MARK: - MyAccountClient

/// A client for the My Account API.
/// Adopting types could be either the root client or a leaf sub-client.
///
/// ## See Also
/// - ``MyAccountError``
public protocol MyAccountClient: Trackable, Loggable {

    /// URL of the My Account API.
    var url: URL { get }

    /// An access token for My Account API.
    var token: String { get }

}

extension MyAccountClient {

    var defaultHeaders: [String: String] {
        return ["Authorization": "Bearer \(token)"]
    }

}

// MARK: - MyAccount

/// Root client for the My Account API.
/// Contains other sub-clients, such as the client for authentication methods.
///
/// ## See Also
/// - ``MyAccountError``
public protocol MyAccount: MyAccountClient {

    // TODO: Complete docs.
    var authenticationMethods: MyAccountAuthenticationMethods { get }

    /// Currently supported version of the My Account API.
    static var apiVersion: String { get }

}
