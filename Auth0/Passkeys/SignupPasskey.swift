#if !os(watchOS)
import Foundation
import AuthenticationServices

public protocol SignupPasskey {

    var credentialID: Data { get }

    // swiftlint:disable:next identifier_name
    var a0_attachment: SignupPasskeyAttachment? { get }

    var rawAttestationObject: Data? { get }

    var rawClientDataJSON: Data { get }

}

public enum SignupPasskeyAttachment: String {

    case platform

    case crossPlatform = "cross-platform"

}

@available(iOS 16.6, macOS 12.0, visionOS 1.0, *)
extension ASAuthorizationPlatformPublicKeyCredentialRegistration: SignupPasskey {

    // swiftlint:disable:next identifier_name
    public var a0_attachment: SignupPasskeyAttachment? {
        switch self.attachment {
        case .platform:
            return SignupPasskeyAttachment.platform
        case .crossPlatform:
            return SignupPasskeyAttachment.crossPlatform
        @unknown default:
            return nil
        }
    }

}

struct PasskeyAttestation {
    let id: String
    let rawId: String
    let attachment: String?
    let attestationObject: String
    let clientData: String
    let authenticatorData: String
    let signature: String
}

@available(iOS 16.6, macOS 12.0, visionOS 1.0, *)
extension SignupPasskey {

    func decode() -> PasskeyAttestation? {
        guard let rawAttestationObject = self.rawAttestationObject else {
            return nil
        }

        let credentialID = self.credentialID.encodeBase64URLSafe()
        let offset = 32 + 1 + 4 // Relying party ID hash (32) + flags (1) + counter (4)

        return PasskeyAttestation(id: credentialID,
                                  rawId: credentialID,
                                  attachment: self.a0_attachment?.rawValue,
                                  attestationObject: rawAttestationObject.encodeBase64URLSafe(),
                                  clientData: self.rawClientDataJSON.encodeBase64URLSafe(),
                                  authenticatorData: rawAttestationObject.prefix(offset).encodeBase64URLSafe(),
                                  signature: rawAttestationObject.suffix(offset).encodeBase64URLSafe())
    }

}
#endif
