#if WEB_AUTH_PLATFORM
import Foundation

///
///  List of supported response_types
///  ImplicitGrant
///  [.token]
///  [.idToken]
///  [.token, .idToken]
///
///  PKCE
///  [.code]
///  [.code, token]
///  [.code, idToken]
///  [.code, token, .idToken]
///
public struct ResponseType: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let token     = ResponseType(rawValue: 1 << 0)
    public static let idToken   = ResponseType(rawValue: 1 << 1)
    public static let code      = ResponseType(rawValue: 1 << 2)

    var label: String? {
        switch self.rawValue {
        case ResponseType.token.rawValue:
            return "token"
        case ResponseType.idToken.rawValue:
            return "id_token"
        case ResponseType.code.rawValue:
            return "code"
        default:
            return nil
        }
    }
}
#endif
