/// Types of passwordless authentication.
public enum PasswordlessType: String {

    /// Simple OTP code sent by email or SMS.
    case code = "code"

    /// Regular Web HTTP link (web only, uses a redirect).
    case webLink = "link"

    /// Universal Link.
    case iOSLink = "link_ios"

    /// Android App Link.
    case androidLink = "link_android"

}
