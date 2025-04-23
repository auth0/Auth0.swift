#if !os(watchOS)
import AuthenticationServices

struct PasskeyAttestation {
    let id: String
    let rawId: String
    let attestationObject: String
    let authenticatorData: String
    let clientData: String
    let credential: String
}

@available(iOS 15.0, macOS 12.0, tvOS 16.0, *)
extension ASAuthorizationPlatformPublicKeyCredentialRegistration {

    func decode() -> PasskeyAttestation? {
        guard let rawAttestationObject = self.rawAttestationObject else {
            return nil
        }

        let credentialOffset = 32 + 1 + 4 // Relying party ID hash (32) + flags (1) + counter (4)

        guard let credentialID = self.credentialID.a0_encodeBase64URLSafe(),
              let clientData = self.rawClientDataJSON.a0_encodeBase64URLSafe(),
              let attestationObject = rawAttestationObject.a0_encodeBase64URLSafe(),
              let authenticatorData = rawAttestationObject.prefix(credentialOffset).a0_encodeBase64URLSafe(),
              let credential = rawAttestationObject.suffix(credentialOffset).a0_encodeBase64URLSafe() else {
            return nil
        }

        return PasskeyAttestation(id: credentialID,
                                  rawId: credentialID,
                                  attestationObject: attestationObject,
                                  authenticatorData: authenticatorData,
                                  clientData: clientData,
                                  credential: credential)
    }

}
#endif
