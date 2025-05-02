#if PASSKEYS_PLATFORM
import Foundation
import AuthenticationServices

/// The login passkey credential obtained from the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.
/// Contains the subset of relevant properties from [`ASAuthorizationPlatformPublicKeyCredentialAssertion`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialassertion).
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
public protocol LoginPasskey {

    var userID: Data! { get }
    var credentialID: Data { get }
    var attachment: ASAuthorizationPublicKeyCredentialAttachment { get }
    var rawClientDataJSON: Data { get }
    var rawAuthenticatorData: Data! { get }
    var signature: Data! { get }

}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
extension ASAuthorizationPlatformPublicKeyCredentialAssertion: LoginPasskey {}
#endif
