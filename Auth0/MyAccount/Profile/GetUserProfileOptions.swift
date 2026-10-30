import Foundation

/// Options for filtering the fields returned by ``MyAccount/getUserProfile(options:)``.
///
/// By default (when `options` is `nil` or both properties are `nil`) the API returns all fields.
/// Use ``fields`` together with ``includeFields`` for fine-grained control.
///
/// ## Usage
///
/// Return only specific fields:
///
/// ```swift
/// let options = GetUserProfileOptions(
///     fields: ["given_name", "family_name", "email", "picture"],
///     includeFields: true   // default — only these fields are returned
/// )
/// ```
///
/// Exclude specific fields (return everything else):
///
/// ```swift
/// let options = GetUserProfileOptions(
///     fields: ["profile_policy"],
///     includeFields: false  // all fields except profile_policy
/// )
/// ```
///
/// Valid field names: `given_name`, `family_name`, `name`, `nickname`, `picture`, `email`,
/// `email_verified`, `phone_number`, `phone_verified`, `username`, `created_at`,
/// `updated_at`, `user_id`, `profile_policy`.
///
/// > Note: ``MyAccountProfile/profilePolicy`` is `nil` whenever `profile_policy` is not part of the
/// > response, that is, when it is not listed in `fields` in inclusion mode, or when it is listed
/// > in exclusion mode.
public struct GetUserProfileOptions: Sendable {

    /// A list of field names to include or exclude in the response.
    ///
    /// The values must be valid profile field names. When this is `nil`, ``includeFields`` is ignored
    /// and all fields are returned.
    public var fields: [String]?

    /// Whether the listed ``fields`` should be included (`true`, default) or excluded (`false`).
    ///
    /// Set to `false` to return all fields *except* those listed in ``fields``.
    /// This property has no effect when ``fields`` is `nil` or empty.
    public var includeFields: Bool?

    /// Creates profile field-selection options.
    ///
    /// - Parameters:
    ///   - fields:        Field names to include or exclude. Defaults to `nil` (return all fields).
    ///   - includeFields: When `true` (default), only the listed fields are returned.
    ///                    When `false`, all fields except the listed ones are returned.
    public init(fields: [String]? = nil, includeFields: Bool? = nil) {
        self.fields = fields
        self.includeFields = includeFields
    }

}
