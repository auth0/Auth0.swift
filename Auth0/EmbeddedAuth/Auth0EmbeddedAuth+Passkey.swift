import Foundation

#if PASSKEYS_PLATFORM

extension Auth0EmbeddedAuth {

    /// Maps a passkey to the `authn_response` object, with only the fields the server accepts, base64url-encoded.
    ///
    /// Max lengths are not checked here: the server decides.
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyAssertion(from passkey: any LoginPasskey) throws -> [String: Any] {
        guard let userID = passkey.userID, !userID.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no user handle. Only discoverable passkeys are supported.")
        }
        guard !passkey.credentialID.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no credential ID.")
        }
        let clientData = passkey.rawClientDataJSON
        guard !clientData.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no client data.")
        }
        guard let authenticatorData = passkey.rawAuthenticatorData, !authenticatorData.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no authenticator data.")
        }
        guard let signature = passkey.signature, !signature.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no signature.")
        }

        return webAuthnCredential(id: passkey.credentialID,
                                  attachment: passkey.attachment.stringValue,
                                  response: [
                                      "clientDataJSON": clientData.encodeBase64URLSafe(),
                                      "authenticatorData": authenticatorData.encodeBase64URLSafe(),
                                      "signature": signature.encodeBase64URLSafe(),
                                      "userHandle": userID.encodeBase64URLSafe()
                                  ])
    }

    /// Maps a passkey registration to the `passkey` object of the sign-up confirmation, with only the fields the server
    /// accepts, base64url-encoded.
    ///
    /// Max lengths are not checked here: the server decides.
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func passkeyRegistration(from passkey: any SignupPasskey) throws -> [String: Any] {
        guard !passkey.credentialID.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no credential ID.")
        }
        let clientData = passkey.rawClientDataJSON
        guard !clientData.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no client data.")
        }
        guard let attestationObject = passkey.rawAttestationObject, !attestationObject.isEmpty else {
            throw PasskeyInputError(message: "This passkey has no attestation object.")
        }

        return webAuthnCredential(id: passkey.credentialID,
                                  attachment: passkey.attachment.stringValue,
                                  response: [
                                      "clientDataJSON": clientData.encodeBase64URLSafe(),
                                      "attestationObject": attestationObject.encodeBase64URLSafe()
                                  ])
    }

    /// The WebAuthn credential object of an assertion or a registration: the credential ID, the type, the attachment
    /// when known, and the `response` of the ceremony.
    ///
    /// `clientExtensionResults` is always empty: the SDK requests no WebAuthn extension, so there is nothing to forward.
    /// It is sent anyway, as a browser does, so that the server can start to use extensions without a new SDK version.
    private func webAuthnCredential(id credentialID: Data,
                                    attachment: String?,
                                    response: [String: String]) -> [String: Any] {
        let id = credentialID.encodeBase64URLSafe()
        var credential: [String: Any] = [
            "id": id,
            "rawId": id,
            "type": "public-key",
            "clientExtensionResults": [String: Any](),
            "response": response
        ]
        if let attachment {
            credential["authenticatorAttachment"] = attachment
        }
        return credential
    }

    /// Fails the request locally because the input is not valid: nothing is sent and the session is kept.
    ///
    /// The message must never contain secrets such as passkey data.
    func invalidInputRequest<T: Sendable>(message: String) -> Request<T, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            requestValidator: [EmbeddedAuthInputValidator(message: message)],
            handle: { _, callback in
                callback(.failure(EmbeddedAuthError(
                    info: ["error": "invalid_input", "error_description": message],
                    statusCode: 0
                )))
            },
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

}

#endif
