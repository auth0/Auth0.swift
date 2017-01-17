// Users.swift
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

import Foundation

/**
 Users endpoints of Auth0 Management API v2
 - seeAlso: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users)
 */
public protocol Users: Trackable, Loggable {

    var token: String { get }
    var url: URL { get }

    /**
     Fetch a user using the it's identifier.

     By default it gets all user's attributes:

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .get(userId)
     .start { print($0) }
     ```

     but you can select which attributes you want:

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .get(userId, fields: ["email", "user_id"])
     .start { print($0) }
     ```

     or even exclude some attributes:

     ```
     Auth0
     .users(token token, domain: "samples.auth0.com")
     .get(userId, fields: ["identities", "app_metadata"], include: false)
     .start { print($0) }
     ```

     - parameter identifier: id of the user
     - parameter fields:     list of user's field names that will be included/excluded in the response. By default all will be retrieved
     - parameter include:    flag that indicates that only the names in 'fields' should be included or excluded in the response. By default it will include them

     - returns: a request that will yield a user
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/get_users_by_id)
     - important: The token must have the scope `read:users` scope
     */
    func get(_ identifier: String, fields: [String], include: Bool) -> Request<ManagementObject, ManagementError>

    /**
     Updates a user's root values (those who are allowed to be updated).

     For example if you need to change `email`:

     ```
     let attributes = UserPatchAttributes()
     .email("newmail@auth0.com", connection: "Username-Password-Authentication", clientId: "MyClientId")
     ```

     or `user_metadata`:

     ```
     let attributes = UserPatchAttributes()
     .userMetadata(["first_name": "John", "last_name": "Appleseed"])

     ```

     and you can even chain several changes together:

     ```
     let attributes = UserPatchAttributes()
     .email("support@auth0.com", verify: true, connection: "Username-Password-Authentication", clientId: "MyClientId")
     .userMetadata(["first_name": "Juan", "last_name": "AuthZero"])
     .appMetadata(["role": "admin"])
     ```

     then just pass the `UserPatchAttributes` to the patch method like:

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .patch(userId, attributes: attributes)
     .start { print($0) }
     ```

     - parameter identifier: id of the user to update
     - parameter attributes: root attributes to be updated

     - returns: a request
     - seeAlso: UserPatchAttributes
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id)
     - important: The token must have one of  the following scopes: `update:users`, `update:users_app_metadata`
     */
    func patch(_ identifier: String, attributes: UserPatchAttributes) -> Request<ManagementObject, ManagementError>

    /**
     Updates only the user's userMetadata field


     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .patch(userId, userMetadata: ["first_name": "Juan", "last_name": "AuthZero"])
     .start { print($0) }
     ```

     - parameter identifier:   id of the user
     - parameter userMetadata: metadata to update

     - returns: a request to patch user_metadata
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id)
     - important: The token must have one of  the following scopes: `update:users`, `update:users_app_metadata`
     */
    func patch(_ identifier: String, userMetadata: [String: Any]) -> Request<ManagementObject, ManagementError>

    /**
     Links a user given it's identifier with a secondary user identifier it's token.
     After this request the primary user will hold another identity in it's 'identities' attribute which will represent the secondary user.

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .link(userId, withOtherUserToken: anotherToken)
     .start { print($0) }
     ```

     - parameter identifier: id of the primary user who will be linked against a secondary one
     - parameter token:      token of the secondary user to link to

     - returns: a request to link two users
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/post_identities)
     - seeAlso: [Link Accounts Guide](https://auth0.com/docs/link-accounts)
     - important: The token must have the following scope `update:current_user_identities`
     */
    func link(_ identifier: String, withOtherUserToken token: String) -> Request<[ManagementObject], ManagementError>

    /**
     Links a user given it's identifier with a secondary user identified by it's id, provider and connection identifier.

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .link(userId, userId: anotherUserId, provider: "auth0", connectionId: "AConnectionID")
     .start { print($0) }
     ```

     - parameter identifier:   id of the primary user who will be linked against a secondary one
     - parameter userId:       id of the secondary user who will be linked
     - parameter provider:     name of the provider of the secondary user. e.g. 'auth0' for Database connections
     - parameter connectionId: id of the connection of the secondary user.

     - returns: a request to link two users
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/post_identities)
     - seeAlso: [Link Accounts Guide](https://auth0.com/docs/link-accounts)
     - important: The token must have the following scope `update:users`
     */
    func link(_ identifier: String, withUser userId: String, provider: String, connectionId: String?) -> Request<[ManagementObject], ManagementError>

    /**
     Removes one identity from a user.

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .unlink(identityId: "an_idenitity_id", provider: "facebook", fromUserId: "a_user_identifier")
     .start { print($0) }
     ```

     - parameter identityId: identifier of the identity to remove
     - parameter provider:   name of the provider of the identity
     - parameter identifier: id of the user who owns the identity

     - returns: a request to remove an identity
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/delete_provider_by_user_id)
     - seeAlso: [Link Accounts Guide](https://auth0.com/docs/link-accounts)
     - important: The token must have the following scope `update:users`
     */
    func unlink(identityId: String, provider: String, fromUserId identifier: String) -> Request<[ManagementObject], ManagementError>
}

extension Users {

    /**
     Fetch a user using the it's identifier.

     By default it gets all user's attributes:

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .get(userId)
     .start { print($0) }
     ```

     but you can select which attributes you want:

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .get(userId, fields: ["email", "user_id"])
     .start { print($0) }
     ```

     or even exclude some attributes:

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .get(userId, fields: ["identities", "app_metadata"], include: false)
     .start { print($0) }
     ```

     - parameter identifier: id of the user
     - parameter fields:     list of user's field names that will be included/excluded in the response. By default all will be retrieved
     - parameter include:    flag that indicates that only the names in 'fields' should be included or excluded in the response. By default it will include them

     - returns: a request that will yield a user
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/get_users_by_id)
     - important: The token must have the scope `read:users` scope
     */
    public func get(_ identifier: String, fields: [String] = [], include: Bool = true) -> Request<ManagementObject, ManagementError> {
        return self.get(identifier, fields: fields, include: include)
    }

    /**
     Links a user given it's identifier with a secondary user identified by it's id, provider and connection identifier.

     ```
     Auth0
     .users(token: token, domain: "samples.auth0.com")
     .link(userId, userId: anotherUserId, provider: "auth0", connectionId: "AConnectionID")
     .start { print($0) }
     ```

     - parameter identifier:   id of the primary user who will be linked against a secondary one
     - parameter userId:       id of the secondary user who will be linked
     - parameter provider:     name of the provider of the secondary user. e.g. 'auth0' for Database connections
     - parameter connectionId: id of the connection of the secondary user.

     - returns: a request to link two users
     - note: [Auth0 Management API docs](https://auth0.com/docs/api/management/v2#!/Users/post_identities)
     - seeAlso: [Link Accounts Guide](https://auth0.com/docs/link-accounts)
     - important: The token must have the following scope `update:users`
     */
    public func link(_ identifier: String, withUser userId: String, provider: String, connectionId: String? = nil) -> Request<[ManagementObject], ManagementError> {
        return self.link(identifier, withUser: userId, provider: provider, connectionId: connectionId)
    }
}

extension Management: Users {

    func get(_ identifier: String, fields: [String], include: Bool) -> Request<ManagementObject, ManagementError> {
        let userPath = "/api/v2/users/\(identifier)"
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
        let userPath = "/api/v2/users/\(identifier)"
        let component = components(baseURL: self.url as URL, path: userPath)

        return Request(session: self.session, url: component.url!, method: "PATCH", handle: self.managementObject, payload: attributes.dictionary, headers: self.defaultHeaders, logger: self.logger, telemetry: self.telemetry)
    }

    func patch(_ identifier: String, userMetadata: [String: Any]) -> Request<ManagementObject, ManagementError> {
        let attributes = UserPatchAttributes().userMetadata(userMetadata)
        return patch(identifier, attributes: attributes)
    }

    func link(_ identifier: String, withOtherUserToken token: String) -> Request<[ManagementObject], ManagementError> {
        return link(identifier, payload: ["link_with": token])
    }

    func link(_ identifier: String, withUser userId: String, provider: String, connectionId: String? = nil) -> Request<[ManagementObject], ManagementError> {
        var payload = [
            "user_id": userId,
            "provider": provider
        ]
        payload["connection_id"] = connectionId
        return link(identifier, payload: payload)
    }

    private func link(_ identifier: String, payload: [String: Any]) -> Request<[ManagementObject], ManagementError> {
        let identitiesPath = "/api/v2/users/\(identifier)/identities"
        let url = components(baseURL: self.url as URL, path: identitiesPath).url!
        return Request(session: self.session, url: url, method: "POST", handle: self.managementObjects, payload: payload, headers: self.defaultHeaders, logger: self.logger, telemetry: self.telemetry)
    }

    func unlink(identityId: String, provider: String, fromUserId identifier: String) -> Request<[ManagementObject], ManagementError> {
        let identityPath = "/api/v2/users/\(identifier)/identities/\(provider)/\(identityId)"
        let url = components(baseURL: self.url as URL, path: identityPath).url!
        return Request(session: self.session, url: url, method: "DELETE", handle: self.managementObjects, headers: self.defaultHeaders, logger: self.logger, telemetry: self.telemetry)
    }
}

private func components(baseURL: URL, path: String) -> URLComponents {
    let url = baseURL.appendingPathComponent(path)
    return URLComponents(url: url, resolvingAgainstBaseURL: true)!
}
