#if PASSKEYS_PLATFORM
import Foundation
import AuthenticationServices

/// The signup passkey credential obtained from the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.
/// Contains the subset of relevant properties from [`ASAuthorizationPlatformPublicKeyCredentialRegistration`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialregistration).
@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
public protocol SignupPasskey: NewPasskey {}

@available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
extension ASAuthorizationPlatformPublicKeyCredentialRegistration: SignupPasskey {}
#endif
