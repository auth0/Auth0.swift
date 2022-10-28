import Foundation

/**
 A dictionary containing a user profile.
 */
public typealias ManagementObject = [String: Any]

/**
 Client for the Users endpoints of the Auth0 [Management API v2](https://auth0.com/docs/api/management/v2).

 ## See Also

 - ``ManagementError``
 */
public protocol Users: Trackable, Loggable {

    /// The Management API token.
    var token: String { get }
    /// The Auth0 Domain URL.
    var url: URL { get }

    // MARK: - Methods

    /**
     Fetches a user using its identifier.

     ## Usage

     By default it gets all the user's attributes:

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .get("user-id")
         .start { result in
             switch result {
             case .success(let user):
                 print("Obtained user: \(user)")
             case .failure(let error):
                 print("Failed with: \(error)")
             }
         }
     ```

     You can select which attributes you want:

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .get("user-id", fields: ["email", "user_id"])
         .start { print($0) }
     ```

     You can even exclude some attributes:

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .get("user-id", fields: ["identities", "app_metadata"], include: false)
         .start { print($0) }
     ```

     - Parameters:
       - identifier: ID of the user. You can get this value from the `sub` claim of the user's ID token, or from the `sub` property of a ``UserInfo`` instance.
       - fields:     List of the user's field names that will be included/excluded in the response. By default all will be retrieved.
       - include:    Flag that indicates that only the names in 'fields' should be included/excluded in the response. By default it will include them.
     - Returns: A request that will yield a user.
     - Requires: The token must have the scope `read:users` scope.

     ## See Also

     - [Management API Endpoint](https://auth0.com/docs/api/management/v2#!/Users/get_users_by_id)
     */
    func get(_ identifier: String, fields: [String], include: Bool) -> Request<ManagementObject, ManagementError>

    /**
     Updates a user's root values (those which are allowed to be updated).

     ## Usage

     For example, if you need to change the  `email`:

     ```swift
     let attributes = UserPatchAttributes().email("new.email@auth0.com",
                                                  connection: "Username-Password-Authentication",
                                                  clientId: clientId)
     ```

     Or, if you need to change the `user_metadata`:

     ```swift
     let attributes = UserPatchAttributes().userMetadata(["first_name": "John", "last_name": "Appleseed"])
     ```

     You can even chain several changes together:

     ```swift
     let attributes = UserPatchAttributes()
         .email("new.email@auth0.com",
                verify: true, 
                connection: "Username-Password-Authentication", 
                clientId: clientId)
         .userMetadata(["first_name": "John", "last_name": "Appleseed"])
         .appMetadata(["role": "admin"])
     ```

     Then, just pass the ``UserPatchAttributes`` to the patch method:

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .patch("user-id", attributes: attributes)
         .start { print($0) }
     ```

     - Parameters:
       - identifier: ID of the user to update. You can get this value from the `sub` claim of the user's ID token, or from the `sub` property of a ``UserInfo`` instance.
       - attributes: Root attributes to be updated.
     - Returns: A request that will yield the updated user.
     - Requires: The token must have one of the following scopes: `update:users`, `update:users_app_metadata`.

     ## See Also

     - ``UserPatchAttributes``
     - [Management API Endpoint](https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id)
     */
    func patch(_ identifier: String, attributes: UserPatchAttributes) -> Request<ManagementObject, ManagementError>

    /**
     Updates only the user's `user_metadata` field.

     ## Usage

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .patch("user-id", userMetadata: ["first_name": "John", "last_name": "Appleseed"])
         .start { print($0) }
     ```

     - Parameters:
       - identifier:   ID of the user to update. You can get this value from the `sub` claim of the user's ID token, or from the `sub` property of a ``UserInfo`` instance.
       - userMetadata: Metadata to update.
     - Returns: A request that will yield the updated user.
     - Requires: The token must have one of the following scopes: `update:users`, `update:users_app_metadata`.

     ## See Also

     - [Management API Endpoint](https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id)
     */
    func patch(_ identifier: String, userMetadata: [String: Any]) -> Request<ManagementObject, ManagementError>

    /**
     Links a user given its identifier with a secondary user given its ID token.
     After this request the primary user will hold another identity in its `identities` attribute, which will represent
     the secondary user.

     ## Usage

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .link("primary-user-id", withOtherUserToken: "secondary-id-token")
         .start { print($0) }
     ```

     - Parameters:
       - identifier: ID of the primary user who will be linked against a secondary one. You can get this value from the `sub` claim of the primary user's ID token, or from the `sub` property of a ``UserInfo`` instance.
       - token:      ID token of the secondary user.
     - Returns: A request to link two users.
     - Requires: The token must have the scope `update:current_user_identities`.

     ## See Also

     - [Management API Endpoint](https://auth0.com/docs/api/management/v2#!/Users/post_identities)
     - [User Account Linking](https://auth0.com/docs/manage-users/user-accounts/user-account-linking)
     */
    func link(_ identifier: String, withOtherUserToken token: String) -> Request<[ManagementObject], ManagementError>

    /**
     Links a user given its identifier with a secondary user given its identifier, provider and connection identifier.

     ## Usage

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .link("primary-user-id", userId: "secondary-user-id", provider: "auth0", connectionId: "connection-id")
         .start { print($0) }
     ```

     - Parameters:
       - identifier:   ID of the primary user who will be linked against a secondary one. You can get this value from the `sub` claim of the primary user's ID token, or from the `sub` property of a ``UserInfo`` instance.
       - userId:       ID of the secondary user. You can get this value from the `sub` claim of the secondary user's ID token, or from the `sub` property of a ``UserInfo`` instance.
       - provider:     Name of the provider for the secondary user, for example 'auth0' for database connections.
       - connectionId: ID of the connection for the secondary user.
     - Returns: A request to link two users.
     - Requires: The token must have the scope `update:users`.

     ## See Also

     - [Management API Endpoint](https://auth0.com/docs/api/management/v2#!/Users/post_identities)
     - [User Account Linking](https://auth0.com/docs/manage-users/user-accounts/user-account-linking)
     */
    func link(_ identifier: String, withUser userId: String, provider: String, connectionId: String?) -> Request<[ManagementObject], ManagementError>

    /**
     Removes an identity from a user.

     ## Usage

     ```swift
     Auth0
         .users(token: credentials.accessToken, domain: domain)
         .unlink(identityId: "identity-id", provider: "github", fromUserId: "user-id")
         .start { print($0) }
     ```

     - Parameters:
       - identityId: ID of the identity to remove.
       - provider:   Name of the identity provider.
       - identifier: ID of the user who owns the identity. You can get this value from the `sub` claim of the user's ID token, or from the `sub` property of a ``UserInfo`` instance.
     - Returns: A request to remove an identity.
     - Requires: The token must have the scope `update:users`.

     ## See Also

     - [Management API Endpoint](https://auth0.com/docs/api/management/v2#!/Users/delete_user_identity_by_user_id)
     - [User Account Linking](https://auth0.com/docs/manage-users/user-accounts/user-account-linking)
     */
    func unlink(identityId: String, provider: String, fromUserId identifier: String) -> Request<[ManagementObject], ManagementError>

}

public extension Users {

    func get(_ identifier: String, fields: [String] = [], include: Bool = true) -> Request<ManagementObject, ManagementError> {
        return self.get(identifier, fields: fields, include: include)
    }

    func link(_ identifier: String, withUser userId: String, provider: String, connectionId: String? = nil) -> Request<[ManagementObject], ManagementError> {
        return self.link(identifier, withUser: userId, provider: provider, connectionId: connectionId)
    }

}

extension Management: Users {

    func get(_ identifier: String, fields: [String], include: Bool) -> Request<ManagementObject, ManagementError> {
        let userPath = "api/v2/users/\(identifier)"
        var component = components(baseURL: self.url as URL, path: userPath)
        let value = fields.joined(separator: ",")
        if !value.isEmpty {
            component.queryItems = [
                URLQueryItem(name: "fields", value: value),
                URLQueryItem(name: "include_fields", value: String(include))
            ]
        }

        return Request(session: self.session, url: component.url!, method: "GET", handle: self.managementObject, headers: self.defaultHeaders, logger: self.logger, telemetry: self.telemetry)
    }

    func patch(_ identifier: String, attributes: UserPatchAttributes) -> Request<ManagementObject, ManagementError> {
        let userPath = "api/v2/users/\(identifier)"
        let component = components(baseURL: self.url as URL, path: userPath)

        return Request(session: self.session, url: component.url!, method: "PATCH", handle: self.managementObject, parameters: attributes.dictionary, headers: self.defaultHeaders, logger: self.logger, telemetry: self.telemetry)
    }

    func patch(_ identifier: String, userMetadata: [String: Any]) -> Request<ManagementObject, ManagementError> {
        let attributes = UserPatchAttributes().userMetadata(userMetadata)
        return patch(identifier, attributes: attributes)
    }

    func link(_ identifier: String, withOtherUserToken token: String) -> Request<[ManagementObject], ManagementError> {
        return link(identifier, parameters: ["link_with": token])
    }

    func link(_ identifier: String, withUser userId: String, provider: String, connectionId: String? = nil) -> Request<[ManagementObject], ManagementError> {
        var payload = [
            "user_id": userId,
            "provider": provider
        ]
        payload["connection_id"] = connectionId
        return link(identifier, parameters: payload)
    }

    private func link(_ identifier: String, parameters: [String: Any]) -> Request<[ManagementObject], ManagementError> {
        let identitiesPath = "api/v2/users/\(identifier)/identities"
        let url = components(baseURL: self.url as URL, path: identitiesPath).url!
        return Request(session: self.session, url: url, method: "POST", handle: self.managementObjects, parameters: parameters, headers: self.defaultHeaders, logger: self.logger, telemetry: self.telemetry)
    }

    func unlink(identityId: String, provider: String, fromUserId identifier: String) -> Request<[ManagementObject], ManagementError> {
        let identityPath = "api/v2/users/\(identifier)/identities/\(provider)/\(identityId)"
        let url = components(baseURL: self.url as URL, path: identityPath).url!
        return Request(session: self.session, url: url, method: "DELETE", handle: self.managementObjects, headers: self.defaultHeaders, logger: self.logger, telemetry: self.telemetry)
    }
}

private func components(baseURL: URL, path: String) -> URLComponents {
    let url = baseURL.appendingPathComponent(path)
    return URLComponents(url: url, resolvingAgainstBaseURL: true)!
}
