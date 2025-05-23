#if PASSKEYS_PLATFORM
import Foundation
import AuthenticationServices

/// The signup passkey credential obtained from the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.
/// Contains the subset of relevant properties from [`ASAuthorizationPlatformPublicKeyCredentialRegistration`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialregistration).
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
public protocol NewPasskey {

    var credentialID: Data { get }
    var attachment: ASAuthorizationPublicKeyCredentialAttachment { get }
    var rawClientDataJSON: Data { get }
    var rawAttestationObject: Data? { get }

}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
extension ASAuthorizationPlatformPublicKeyCredentialRegistration: NewPasskey {}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
extension ASAuthorizationPublicKeyCredentialAttachment {

    public var stringValue: String? {
        switch self {
        case .platform:
            return "platform"
        case .crossPlatform:
            return "cross-platform"
        @unknown default:
            return nil
        }
    }

}
#endif
