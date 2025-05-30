import Foundation

// MARK: - Factory Methods

/// Auth0 My Account API client for managing the current user's account.
///
/// ## Usage
///
/// ```swift
/// Auth0.myAccount(token: apiCredentials.accessToken, domain: "samples.us.auth0.com")
/// ```
///
/// You can use the refresh token to get an access token for the My Account API. Refer to
/// ``CredentialsManager/apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)``,
/// or alternatively ``Authentication/renew(withRefreshToken:audience:scope:)`` if you are not using the
/// ``CredentialsManager``.
///
/// > Note: See [Get a refresh token](https://github.com/auth0/Auth0.swift/blob/master/EXAMPLES.md#get-a-refresh-token)
/// to learn how to obtain a refresh token.
///
/// - Parameters:
///   - token:   Access token for the My Account API with the correct scopes to perform the desired action.
///   - domain:  Domain of your Auth0 account, for example `samples.us.auth0.com`.
///   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
/// - Returns: My Account API client.
public func myAccount(token: String, domain: String, session: URLSession = .shared) -> MyAccount {
    return Auth0MyAccount(token: token, url: .httpsURL(from: domain), session: session)
}

/// Auth0 My Account API client for managing the current user's account.
///
/// ## Usage
///
/// ```swift
/// Auth0.myAccount(token: apiCredentials.accessToken)
/// ```
///
/// You can use the refresh token to get an access token for the My Account API. Refer to
/// ``CredentialsManager/apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)``,
/// or alternatively ``Authentication/renew(withRefreshToken:audience:scope:)`` if you are not using the
/// ``CredentialsManager``.
///
/// > Note: See [Get a refresh token](https://github.com/auth0/Auth0.swift/blob/master/EXAMPLES.md#get-a-refresh-token)
/// to learn how to obtain a refresh token.
///
/// The Auth0 Domain is loaded from the `Auth0.plist` file in your main bundle. It should have the following content:
///
/// ```xml
/// <?xml version="1.0" encoding="UTF-8"?>
/// <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
/// <plist version="1.0">
/// <dict>
///     <key>ClientId</key>
///     <string>YOUR_AUTH0_CLIENT_ID</string>
///     <key>Domain</key>
///     <string>YOUR_AUTH0_DOMAIN</string>
/// </dict>
/// </plist>
/// ```
///
/// - Parameters:
///   - token:   Access token for the My Account API with the correct scopes to perform the desired action.
///   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
///   - bundle:  Bundle used to locate the `Auth0.plist` file. Defaults to `Bundle.main`
/// - Returns: My Account API client.
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

/// My Account API client for managing the current user's account.
///
/// ## See Also
/// - ``MyAccountError``
public protocol MyAccount: MyAccountClient {

    /// My Account API sub-client for managing the current user's authentication methods.
    var authenticationMethods: MyAccountAuthenticationMethods { get }

    /// Currently supported version of the My Account API.
    static var apiVersion: String { get }

}
