#if WEB_AUTH_PLATFORM
import Foundation

/**
 List of possible web-based authentication errors

 - NoBundleIdentifierFound:        Cannot get the App's Bundle Identifier to use for redirect_uri.
 - CannotDismissWebAuthController: When trying to dismiss WebAuth controller, no presenter controller could be found.
 - UserCancelled:                  User cancelled the web-based authentication, e.g. tapped the "Done" button in SFSafariViewController
 - PKCENotAllowed:                 PKCE for the supplied Auth0 ClientId was not allowed. You need to set the `Token Endpoint Authentication Method` to `None` in your Auth0 Dashboard
 - missingAccessToken:             access_token missing in response
 */
public enum WebAuthError: CustomNSError {
    case noBundleIdentifierFound
    case cannotDismissWebAuthController
    case userCancelled
    case pkceNotAllowed(String)
    case missingResponseParam(String)
    case missingAccessToken
    case unknownError

    static let genericFoundationCode = 1
    static let cancelledFoundationCode = 0

    public static let infoKey = "com.auth0.webauth.error.info"
    public static let errorDomain: String = "com.auth0.webauth"

    public var errorCode: Int {
        switch self {
        case .userCancelled:
            return WebAuthError.cancelledFoundationCode
        default:
            return WebAuthError.genericFoundationCode
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case .userCancelled:
            return [
                NSLocalizedDescriptionKey: "User Cancelled Web Authentication",
                WebAuthError.infoKey: self
            ]
        case .pkceNotAllowed(let message):
            return [
                NSLocalizedDescriptionKey: message,
                WebAuthError.infoKey: self
            ]
        case .missingAccessToken:
            return [
                NSLocalizedDescriptionKey: "Could not validate the token",
                WebAuthError.infoKey: self
            ]
        default:
            return [
                NSLocalizedDescriptionKey: "Failed to perform webAuth",
                WebAuthError.infoKey: self
            ]
        }
    }
}
#endif
