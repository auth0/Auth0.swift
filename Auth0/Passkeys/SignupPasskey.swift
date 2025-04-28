#if !os(watchOS)
import Foundation
import AuthenticationServices

/// The signup passkey credential obtained from the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.
/// Contains the subset of relevant properties from [`ASAuthorizationPlatformPublicKeyCredentialRegistration`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialregistration).
@available(iOS 16.6, macOS 12.0, visionOS 1.0, *)
public protocol SignupPasskey {

    var credentialID: Data { get }
    var attachment: ASAuthorizationPublicKeyCredentialAttachment { get }
    var rawAttestationObject: Data? { get }
    var rawClientDataJSON: Data { get }

}

@available(iOS 16.6, macOS 12.0, visionOS 1.0, *)
extension ASAuthorizationPlatformPublicKeyCredentialRegistration: SignupPasskey {}

@available(iOS 16.6, macOS 12.0, visionOS 1.0, *)
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
