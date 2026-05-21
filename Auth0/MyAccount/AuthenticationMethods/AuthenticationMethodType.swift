/// The type of authentication method to filter by when listing authentication methods.
///
/// ## See Also
///
/// - ``MyAccountAuthenticationMethods/getAuthenticationMethods(type:)``
public enum AuthenticationMethodType: String {
    case password
    case passkey
    case webauthnPlatform = "webauthn-platform"
    case webauthnRoaming = "webauthn-roaming"
    case totp
    case phone
    case email
    case pushNotification = "push-notification"
    case recoveryCode = "recovery-code"
}
