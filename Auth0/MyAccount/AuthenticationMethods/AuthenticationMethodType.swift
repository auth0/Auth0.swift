/// The type of authentication method to filter by when listing authentication methods.
public enum AuthenticationMethodType: String, Sendable {
    case password
    case passkey
    case webAuthnPlatform = "webauthn-platform"
    case webAuthnRoaming = "webauthn-roaming"
    case totp
    case phone
    case email
    case pushNotification = "push-notification"
    case recoveryCode = "recovery-code"
}
