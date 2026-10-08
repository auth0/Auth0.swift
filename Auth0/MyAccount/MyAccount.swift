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
public protocol MyAccountClient: Trackable, Loggable, SenderConstraining {

    /// URL of the My Account API.
    var url: URL { get }

    /// An access token for My Account API.
    var token: String { get }

}

extension MyAccountClient {

    var defaultHeaders: [String: String] {
        return baseHeaders(accessToken: token, tokenType: dpop != nil ? "DPoP" : "Bearer")
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

    /// Retrieves the authenticated user's profile.
    ///
    /// Returns the user's profile attributes along with a per-field access policy
    /// (``MyAccountProfile/profilePolicy``) that indicates which fields are editable.
    ///
    /// ## Scopes Required
    ///
    /// `read:me:profile`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .getUserProfile(options: nil)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let profile):
    ///             print("User profile: \(profile)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// Use ``GetUserProfileOptions`` to limit which fields are returned:
    ///
    /// ```swift
    /// let options = GetUserProfileOptions(
    ///     fields: ["given_name", "family_name", "email"],
    ///     includeFields: true
    /// )
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .getUserProfile(options: options)
    ///     .start { result in ... }
    /// ```
    ///
    /// - Note: A `MyAccountError` with `statusCode == 404` means the **My Account Profile**
    ///   feature is not enabled for this tenant. Contact Auth0 support to enable it.
    ///
    /// - Parameter options: Field-selection options. Pass `nil` to return all fields.
    /// - Returns: A request that will yield the user's ``MyAccountProfile``.
    ///
    /// ## See Also
    ///
    /// - ``MyAccountProfile``
    /// - ``GetUserProfileOptions``
    /// - ``MyAccountError``
    func getUserProfile(options: GetUserProfileOptions?) -> any Requestable<MyAccountProfile, MyAccountError>

    /// Updates the authenticated user's writable profile attributes.
    ///
    /// Only the fields you set on ``UpdateUserProfileRequest`` are sent; omitted fields leave
    /// the stored values unchanged. The update is all-or-nothing — if any field is read-only or
    /// fails validation, the entire request is rejected.
    ///
    /// Returns the full updated profile, regardless of any field-selection options.
    ///
    /// ## Scopes Required
    ///
    /// `update:me:profile`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let request = UpdateUserProfileRequest(
    ///     nickname: "wonderland_alice",
    ///     userMetadata: ["theme": "dark", "old_key": nil]   // nil deletes "old_key"
    /// )
    ///
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .updateUserProfile(request)
    ///     .start { result in
    ///         switch result {
    ///         case .success(let profile):
    ///             print("Updated profile: \(profile)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Note: A `MyAccountError` with `statusCode == 404` means the **My Account Profile**
    ///   feature is not enabled for this tenant. Contact Auth0 support to enable it.
    ///
    /// - Parameter request: The profile attributes to update.
    /// - Returns: A request that will yield the updated ``MyAccountProfile``.
    ///
    /// ## See Also
    ///
    /// - ``MyAccountProfile``
    /// - ``UpdateUserProfileRequest``
    /// - ``MyAccountError``
    func updateUserProfile(_ request: UpdateUserProfileRequest) -> any Requestable<MyAccountProfile, MyAccountError>

}

// MARK: - Profile convenience

public extension MyAccount {

    /// Retrieves the authenticated user's profile with all fields.
    ///
    /// Convenience overload of ``getUserProfile(options:)`` that returns all profile fields.
    ///
    /// ## Scopes Required
    ///
    /// `read:me:profile`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Auth0
    ///     .myAccount(token: apiCredentials.accessToken)
    ///     .getUserProfile()
    ///     .start { result in
    ///         switch result {
    ///         case .success(let profile):
    ///             print("User profile: \(profile)")
    ///         case .failure(let error):
    ///             print("Failed with: \(error)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Returns: A request that will yield the user's ``MyAccountProfile``.
    func getUserProfile() -> any Requestable<MyAccountProfile, MyAccountError> {
        return getUserProfile(options: nil)
    }

}
