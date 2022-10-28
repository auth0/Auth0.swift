import Foundation

/// User attributes that can be updated using the ``Users/patch(_:attributes:)`` method of ``Users``.
final public class UserPatchAttributes {

    private(set) var dictionary: [String: Any]

    /**
     Creates a new `UserPatchAttributes` instance.

     - Parameter dictionary: Default attribute values.
     */
    public init(dictionary: [String: Any] = [:]) {
        self.dictionary = dictionary
    }

    /**
     Mark/unmark a user as blocked.

     - Parameter blocked: If the user is blocked.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func blocked(_ blocked: Bool) -> UserPatchAttributes {
        dictionary["blocked"] = blocked
        return self
    }

    /**
     Change the email of the user.

     - Parameters:
       - email:      New email for the user.
       - verified:   If the email is verified.
       - verify:     If the user should verify the email.
       - connection: Name of the connection.
       - clientId:   Auth0 Client ID.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func email(_ email: String, verified: Bool? = nil, verify: Bool? = nil, connection: String, clientId: String) -> UserPatchAttributes {
        dictionary["email"] = email
        dictionary["verify_email"] = verify
        dictionary["email_verified"] = verified
        dictionary["connection"] = connection
        dictionary["client_id"] = clientId
        return self
    }

    /**
     Set the verified status of the email.

     - Parameters:
       - verified:   If the email is verified.
       - connection: Name of the connection.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func emailVerified(_ verified: Bool, connection: String) -> UserPatchAttributes {
        dictionary["email_verified"] = verified
        dictionary["connection"] = connection
        return self
    }

    /**
     Change the phone number of the user (SMS connection only).

     - Parameters:
       - phoneNumber: New phone number for the user.
       - verified:    If the phone number is verified.
       - verify:      If the user should verify the phone number.
       - connection:  Name of the connection.
       - clientId:    Auth0 Client ID.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func phoneNumber(_ phoneNumber: String, verified: Bool? = nil, verify: Bool? = nil, connection: String, clientId: String) -> UserPatchAttributes {
        dictionary["phone_number"] = phoneNumber
        dictionary["verify_phone_number"] = verify
        dictionary["phone_verified"] = verified
        dictionary["connection"] = connection
        dictionary["client_id"] = clientId
        return self
    }

    /**
     Set the verified status of the phone number.

     - Parameters:
       - verified:   If the phone number is verified or not.
       - connection: Name of the connection.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func phoneVerified(_ verified: Bool, connection: String) -> UserPatchAttributes {
        dictionary["phone_verified"] = verified
        dictionary["connection"] = connection
        return self
    }

    /**
     Change the user's password.

     - Parameters:
       - password:   New password for the user.
       - verify:     If the password should be verified by the user.
       - connection: Name of the connection.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func password(_ password: String, verify: Bool? = nil, connection: String) -> UserPatchAttributes {
        dictionary["password"] = password
        dictionary["connection"] = connection
        dictionary["verify_password"] = verify
        return self
    }

    /**
     Change the username.

     - Parameters:
       - username:   New username for the user.
       - connection: Name of the connection.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func username(_ username: String, connection: String) -> UserPatchAttributes {
        dictionary["username"] = username
        dictionary["connection"] = connection
        return self
    }

    /**
     Update user metadata.

     - Parameter metadata: New user metadata values.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func userMetadata(_ metadata: [String: Any]) -> UserPatchAttributes {
        dictionary["user_metadata"] = metadata
        return self
    }

    /**
     Update app metadata.

     - Parameter metadata: New app metadata values.
     - Returns: The same `UserPatchAttributes` instance to allow method chaining.
     */
    public func appMetadata(_ metadata: [String: Any]) -> UserPatchAttributes {
        dictionary["app_metadata"] = metadata
        return self
    }

}
