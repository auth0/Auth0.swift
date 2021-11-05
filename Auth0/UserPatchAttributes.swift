import Foundation

/// Atributes of the user allowed to update using `patch()` method of `Users`
public class UserPatchAttributes {

    private(set) var dictionary: [String: Any]

    /**
     Creates a new attributes

     - parameter dictionary: default attribute values

     - returns: new attributes
     */
    public init(dictionary: [String: Any] = [:]) {
        self.dictionary = dictionary
    }

    /**
     Mark/Unmark a user as blocked

     - parameter blocked: if the user is blocked

     - returns: itself
     */
    public func blocked(_ blocked: Bool) -> UserPatchAttributes {
        dictionary["blocked"] = blocked
        return self
    }

    /**
     Changes the email of the user

     - parameter email:      new email for the user
     - parameter verified:   if the email is verified
     - parameter verify:     if the user should verify the email
     - parameter connection: name of the connection
     - parameter clientId:   Auth0 clientId

     - returns: itself
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
     Sets the verified status of the email

     - parameter verified:   if the email is verified or not
     - parameter connection: connection name

     - returns: itself
     */
    public func emailVerified(_ verified: Bool, connection: String) -> UserPatchAttributes {
        dictionary["email_verified"] = verified
        dictionary["connection"] = connection
        return self
    }

    /**
     Changes the phone number of the user (SMS connection only)

     - parameter phoneNumber:   new phone number for the user
     - parameter verified:      if the phone number is verified
     - parameter verify:        if the user should verify the phone number
     - parameter connection:    name of the connection
     - parameter clientId:   	Auth0 clientId

     - returns: itself
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
     Sets the verified status of the phone number

     - parameter verified:   if the phone number is verified or not
     - parameter connection: connection name

     - returns: itself
     */
    public func phoneVerified(_ verified: Bool, connection: String) -> UserPatchAttributes {
        dictionary["phone_verified"] = verified
        dictionary["connection"] = connection
        return self
    }

    /**
     Changes the user's password

     - parameter password:   new password for the user
     - parameter verify:     if the password should be verified by the user
     - parameter connection: name of the connection

     - returns: itself
     */
    public func password(_ password: String, verify: Bool? = nil, connection: String) -> UserPatchAttributes {
        dictionary["password"] = password
        dictionary["connection"] = connection
        dictionary["verify_password"] = verify
        return self
    }

    /**
     Changes the username

     - parameter username:   new username
     - parameter connection: name of the connection

     - returns: itself
     */
    public func username(_ username: String, connection: String) -> UserPatchAttributes {
        dictionary["username"] = username
        dictionary["connection"] = connection
        return self
    }

    /**
     Updates user metadata

     - parameter metadata: new user metadata values

     - returns: itself
     */
    public func userMetadata(_ metadata: [String: Any]) -> UserPatchAttributes {
        dictionary["user_metadata"] = metadata
        return self
    }

    /**
     Updates app metadata

     - parameter metadata: new app metadata values

     - returns: itself
     */
    public func appMetadata(_ metadata: [String: Any]) -> UserPatchAttributes {
        dictionary["app_metadata"] = metadata
        return self
    }
}
