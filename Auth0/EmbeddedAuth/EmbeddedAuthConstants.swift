import Foundation

// MARK: - Wire string constants

/// `grant_type` values returned by the `/e/discovery` endpoint.
enum GrantTypeValue {
    static let authorizationCode = "authorization_code"
    static let tokenExchange = "urn:ietf:params:oauth:grant-type:token-exchange"
    static let password = "password"
    static let webAuthn = "urn:okta:params:oauth:grant-type:webauthn"
    static let passwordlessOTP = "http://auth0.com/oauth/grant-type/passwordless/otp"
    static let passwordRealm = "http://auth0.com/oauth/grant-type/password-realm"
}

/// `identifier_types` values for a passwordless OTP alternative.
enum IdentifierTypeValue {
    static let email = "email"
    static let phoneNumber = "phone_number"
}

/// `type` discriminator values returned by the `/e/discovery` endpoint.
enum TypeValue {
    /// Passwordless flow using the Auth0 (`/otp/challenge`) flow rather than the legacy one.
    static let auth0 = "auth0"
    /// An `authorization_code` alternative that supports embedded authorization.
    static let embeddedAuthorize = "embedded_authorize"
}
