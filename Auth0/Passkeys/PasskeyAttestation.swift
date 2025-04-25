#if !os(watchOS)
import AuthenticationServices

struct PasskeyAttestation {
    let id: String
    let rawId: String
    let attachment: String?
    let attestationObject: String
    let clientData: String
    let authenticatorData: String
    let signature: String
}

@available(iOS 16.6, macOS 12.0, tvOS 16.0, *)
extension ASAuthorizationPlatformPublicKeyCredentialRegistration {

    func decode() -> PasskeyAttestation? {
        guard let rawAttestationObject = self.rawAttestationObject else {
            return nil
        }

        let credentialID = self.credentialID.encodeBase64URLSafe()
        let offset = 32 + 1 + 4 // Relying party ID hash (32) + flags (1) + counter (4)

        return PasskeyAttestation(id: credentialID,
                                  rawId: credentialID,
                                  attachment: self.attachment.stringValue,
                                  attestationObject: rawAttestationObject.encodeBase64URLSafe(),
                                  clientData: self.rawClientDataJSON.encodeBase64URLSafe(),
                                  authenticatorData: rawAttestationObject.prefix(offset).encodeBase64URLSafe(),
                                  signature: rawAttestationObject.suffix(offset).encodeBase64URLSafe())
    }

}

@available(iOS 16.6, macOS 12.0, tvOS 16.0, *)
extension ASAuthorizationPublicKeyCredentialAttachment {

    var stringValue: String? {
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
