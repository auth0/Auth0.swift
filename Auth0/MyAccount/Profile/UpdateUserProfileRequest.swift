import Foundation

/// A request body for updating the authenticated user's writable profile attributes.
///
/// Only the fields you set are sent; omitted fields leave the corresponding profile attributes
/// unchanged. An empty request (`UpdateUserProfileRequest()`) is valid and is a no-op.
///
/// ## Usage
///
/// Update a single field:
///
/// ```swift
/// let request = UpdateUserProfileRequest(nickname: "wonderland_alice")
/// ```
///
/// Update multiple fields at once:
///
/// ```swift
/// let request = UpdateUserProfileRequest(
///     givenName: "Alice",
///     nickname: "wonderland_alice",
///     picture: "https://example.com/alice.jpg"
/// )
/// ```
///
/// > Important: The update is all-or-nothing. If any field is read-only or fails validation,
/// > the entire request is rejected and a ``MyAccountError`` is returned.
///
/// ## See Also
/// - ``MyAccount/updateUserProfile(_:)``
/// - ``MyAccountError``
public struct UpdateUserProfileRequest: Sendable {

    /// The user's given name (first name or forename). Maximum 150 characters.
    public var givenName: String?

    /// The user's family name (last name or surname). Maximum 150 characters.
    public var familyName: String?

    /// The user's full name. Maximum 300 characters.
    public var name: String?

    /// The user's preferred nickname or alias. Maximum 300 characters.
    public var nickname: String?

    /// URL of the user's profile picture, photo, or avatar.
    ///
    /// Must be a valid HTTPS URL. Maximum 2048 characters.
    public var picture: String?

    /// Creates a profile update request.
    ///
    /// - Parameters:
    ///   - givenName:     Updated given name. Defaults to `nil` (unchanged).
    ///   - familyName:    Updated family name. Defaults to `nil` (unchanged).
    ///   - name:          Updated full name. Defaults to `nil` (unchanged).
    ///   - nickname:      Updated nickname. Defaults to `nil` (unchanged).
    ///   - picture:       Updated picture URL (HTTPS). Defaults to `nil` (unchanged).
    public init(givenName: String? = nil,
                familyName: String? = nil,
                name: String? = nil,
                nickname: String? = nil,
                picture: String? = nil) {
        self.givenName = givenName
        self.familyName = familyName
        self.name = name
        self.nickname = nickname
        self.picture = picture
    }

}

// MARK: - Internal payload builder

extension UpdateUserProfileRequest {

    /// Builds the `[String: Any]` payload that `JSONSerialization` encodes as the PATCH body.
    var toPayload: [String: Any] {
        var payload: [String: Any] = [:]
        if let givenName { payload["given_name"] = givenName }
        if let familyName { payload["family_name"] = familyName }
        if let name { payload["name"] = name }
        if let nickname { payload["nickname"] = nickname }
        if let picture { payload["picture"] = picture }
        return payload
    }

}
