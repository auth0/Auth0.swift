import Foundation

/**
 A dictionary containing a user profile.
 */
public typealias ManagementObject = [String: Any]

/**
 Users endpoints of Auth0 Management API v2.

 - See: ``ManagementError``
 - See: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users)
 */
public protocol Users: Trackable, Loggable {

    /// The Management API token.
    var token: String { get }
    /// The Auth0 Domain URL.
    var url: URL { get }

    /**
     Fetch a user using its identifier.
     By default it gets all the user's attributes:

     ```
     Auth0
         .users(token: token, domain: "samples.auth0.com")
         .get(userId)
         .start { result in
             switch result {
             case .success(let user):
                 print("User signed up: \(user)")
             case .failure(let error):
                 print("Failed with \(error)")
             }
         }
     ```

     You can select which attributes you want:

     ```
     Auth0
         .users(token: token, domain: "samples.auth0.com")
         .get(userId, fields: ["email", "user_id"])
         .start { print($0) }
     ```

     You can even exclude some attributes:

     ```
     Auth0
         .users(token token, domain: "samples.auth0.com")
         .get(userId, fields: ["identities", "app_metadata"], include: false)
         .start { print($0) }
     ```

     - Parameters:
       - identifier: ID of the user.
       - fields:     List of the user's field names that will be included/excluded in the response. By default all will be retrieved.
       - include:    Flag that indicates that only the names in 'fields' should be included or not in the response. By default it will include them.
     - Returns: A request that will yield a user.
     - Note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/get_users_by_id).
     - Important: The token must have the scope `read:users` scope.
     */
    func get(_ identifier: String, fields: [String], include: Bool) -> Request<ManagementObject, ManagementError>

    /**
     Updates a user's root values (those which are allowed to be updated).
     For example if you need to change `email`:

     ```
     let attributes = UserPatchAttributes().email("newmail@auth0.com", 
                                                  connection: "Username-Password-Authentication", 
                                                  clientId: "MyClientId")
     ```

     Or if you need to change `user_metadata`:

     ```
     let attributes = UserPatchAttributes().userMetadata(["first_name": "John", "last_name": "Appleseed"])
     ```

     You can even chain several changes together:

     ```
     let attributes = UserPatchAttributes()
         .email("support@auth0.com", 
                verify: true, 
                connection: "Username-Password-Authentication", 
                clientId: "MyClientId")
         .userMetadata(["first_name": "Juan", "last_name": "AuthZero"])
         .appMetadata(["role": "admin"])
     ```

     Then just pass the ``UserPatchAttributes`` to the patch method, like:

     ```
     Auth0
         .users(token: token, domain: "samples.auth0.com")
         .patch(userId, attributes: attributes)
         .start { print($0) }
     ```

     - Parameters:
       - identifier: ID of the user to update.
       - attributes: Root attributes to be updated.
     - Returns: A request.
     - See: ``UserPatchAttributes``
     - Note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id).
     - Important: The token must have one of  the following scopes: `update:users`, `update:users_app_metadata`.
     */
    func patch(_ identifier: String, attributes: UserPatchAttributes) -> Request<ManagementObject, ManagementError>

    /**
     Updates only the user's `user_metadata` field.

     ```
     Auth0
         .users(token: token, domain: "samples.auth0.com")
         .patch(userId, userMetadata: ["first_name": "Juan", "last_name": "AuthZero"])
         .start { print($0) }
     ```

     - Parameters:
       - identifier:   ID of the user.
       - userMetadata: Metadata to update.
     - Returns: A request to patch `user_metadata`.
     - Note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id).
     - Important: The token must have one of  the following scopes: `update:users`, `update:users_app_metadata`.
     */
    func patch(_ identifier: String, userMetadata: [String: Any]) -> Request<ManagementObject, ManagementError>

    /**
     Links a user given its identifier with a secondary user identifier its token.
     After this request the primary user will hold another identity in its `identities` attribute which will represent the secondary user.

     ```
     Auth0
         .users(token: token, domain: "samples.auth0.com")
         .link(userId, withOtherUserToken: anotherToken)
         .start { print($0) }
     ```

     - Parameters:
       - identifier:         ID of the primary user who will be linked against a secondary one.
       - withOtherUserToken: Token of the secondary user to link to.
     - Returns: A request to link two users.
     - Note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/post_identities).
     - See: [Link Accounts Guide](https://auth0.com/docs/users/user-account-linking).
     - Important: The token must have the scope `update:current_user_identities`.
     */
    func link(_ identifier: String, withOtherUserToken token: String) -> Request<[ManagementObject], ManagementError>

    /**
     Links a user given its identifier with a secondary user identified by its id, provider and connection identifier.

     ```
     Auth0
         .users(token: token, domain: "samples.auth0.com")
         .link(userId, userId: anotherUserId, provider: "auth0", connectionId: "AConnectionID")
         .start { print($0) }
     ```

     - Parameters:
       - identifier:   ID of the primary user who will be linked against a secondary one.
       - withUser:     ID of the secondary user who will be linked.
       - provider:     Name of the provider of the secondary user, e.g. 'auth0' for Database connections.
       - connectionId: ID of the connection of the secondary user.
     - Returns: A request to link two users.
     - Note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/post_identities).
     - See: [Link Accounts Guide](https://auth0.com/docs/users/user-account-linking).
     - Important: The token must have the scope `update:users`.
     */
    func link(_ identifier: String, withUser userId: String, provider: String, connectionId: String?) -> Request<[ManagementObject], ManagementError>

    /**
     Removes an identity from a user.

     ```
     Auth0
         .users(token: token, domain: "samples.auth0.com")
         .unlink(identityId: "an_idenitity_id", provider: "facebook", fromUserId: "a_user_identifier")
         .start { print($0) }
     ```

     - Parameters:
       - identityId: Identifier of the identity to remove.
       - provider:   Name of the provider of the identity.
       - fromUserId: ID of the user who owns the identity.
     - Returns: A request to remove an identity.
     - Note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/delete_provider_by_user_id).
     - See: [Link Accounts Guide](https://auth0.com/docs/users/user-account-linking).
     - Important: The token must have the scope `update:users`.
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
