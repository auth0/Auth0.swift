import Foundation

// MARK: - Result alias

/// `Result` wrapper for Embedded Login operations.
public typealias EmbeddedAuthResult<T> = Result<T, EmbeddedAuthError>

// MARK: - IdentifierType

/// The type of identifier a user submits during the identify step.
public enum IdentifierType: Sendable, Equatable {
    /// An email address.
    case email
    /// A phone number.
    case phone
    /// A username.
    case username
}

// MARK: - Protocol

/// Client for Embedded Login's interactive authorization loop (`POST /e/authorize`).
///
/// Obtain an instance via ``Auth0/embeddedAuth(clientId:domain:session:)`` or
/// ``Auth0/embeddedAuth(session:bundle:)``.
///
/// ## Usage
///
/// ```swift
/// let client = Auth0.embeddedAuth()
///
/// // Drive the authorization loop
/// do {
///     try await client.authorize(connection: "my-connection").start()
/// } catch let error as EmbeddedAuthError {
///     if case .insufficientAuthorization(_, let nextActions) = error.reason {
///         // nextActions tells you which step to present
///     }
/// }
/// let credentials = try await client.verifyOtp("123456", type: .oob).start()
/// ```
///
/// ## See Also
/// - ``EmbeddedAuthError``
/// - ``NextAction``
public protocol EmbeddedAuth: Trackable, Loggable, Sendable {

    /// Starts a new embedded authorization flow.
    ///
    /// Calls `POST /e/authorize` with `capabilities` advertised.
    /// Always throws ``EmbeddedAuthError`` with ``EmbeddedAuthError/reason`` equal to
    /// ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)``
    /// on the first call; read its associated `nextActions` to determine which step to present.
    ///
    /// The server only offers the username step when
    /// ``EmbeddedCapability/verifyPassword`` is also advertised. Otherwise it answers with `access_denied`,
    /// which this SDK reports as ``EmbeddedAuthErrorReason/accessDenied``. The default ``EmbeddedCapability/all``
    /// includes both.
    ///
    /// The default ``EmbeddedCapability/all`` also advertises ``EmbeddedCapability/verifyPasskey`` where the platform
    /// supports passkeys, so the server may offer ``NextAction/verifyPasskey(options:)``. Choose the step to present
    /// by the type of the entry in `nextActions`, never by its position. To turn passkey sign-in off, pass an explicit
    /// list of capabilities without ``EmbeddedCapability/verifyPasskey``.
    ///
    /// - Parameters:
    ///   - connection:   Connection name to target.
    ///   - capabilities: Actions this SDK version supports. Defaults to ``EmbeddedCapability/all``.
    ///   - scope:        OAuth scope string. Defaults to `"openid profile email offline_access"`.
    ///   - audience:     Optional API audience.
    func authorize(connection: String,
                   capabilities: [EmbeddedCapability],
                   scope: String,
                   audience: String?) -> Request<Void, EmbeddedAuthError>

    /// Submits a user identifier to continue the authorization flow.
    ///
    /// Requires an active session (``authorize(connection:capabilities:scope:audience:)`` must have been called first).
    /// - Parameters:
    ///   - identifier: The identifier value (e.g. an email address, a phone number or a username).
    ///   - type: The type of identifier being submitted.
    func identify(_ identifier: String, type: IdentifierType) -> Request<Void, EmbeddedAuthError>

    /// Requests that the server send an email OTP challenge.
    ///
    /// Requires an active session.
    /// - Parameter index: The `index` of the ``NextAction/challengeEmail(index:identifier:)`` you are acting on.
    ///   It selects one of the user's enrolled email authenticators; it is not a position in the `nextActions` array.
    ///   Pass it back unchanged.
    func challengeEmail(index: Int) -> Request<Void, EmbeddedAuthError>

    /// Submits a one-time password to verify the user's identity.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    ///
    /// Requires an active session.
    ///
    /// - Parameters:
    ///   - otp:  The one-time code entered by the user.
    ///   - type: Whether the code is OOB (email/SMS) or TOTP.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<Credentials, EmbeddedAuthError>

    /// Submits the user's password to verify their identity.
    ///
    /// Call this when ``NextAction/verifyPassword`` is among the `nextActions`.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    /// If a second factor is also required, the request instead fails with
    /// ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)`` and the MFA actions in `nextActions`.
    ///
    /// Requires an active session.
    ///
    /// - Parameter password: The password entered by the user.
    func verifyPassword(_ password: String) -> Request<Credentials, EmbeddedAuthError>

    /// Requests that the server send a phone OTP challenge via SMS or voice.
    ///
    /// Requires an active session.
    ///
    /// - Parameters:
    ///   - index:          The `index` of the ``NextAction/challengePhone(index:identifier:deliveryMethods:)`` you are acting on.
    ///     It selects one of the user's enrolled phone authenticators; it is not a position in the `nextActions` array.
    ///     Pass it back unchanged.
    ///   - deliveryMethod: Whether to deliver the code via SMS or voice call.
    func challengePhone(index: Int, deliveryMethod: PhoneDeliveryMethod) -> Request<Void, EmbeddedAuthError>

    /// Requests that the server send a push notification to the user's enrolled device.
    ///
    /// Poll the result with ``verifyOob()`` at the interval specified by ``NextAction/verifyOob(pollInMs:)``.
    ///
    /// Requires an active session.
    ///
    /// - Parameter index: The `index` of the ``NextAction/challengePush(index:name:)`` you are acting on.
    ///   It selects one of the user's enrolled push authenticators; it is not a position in the `nextActions` array.
    ///   Pass it back unchanged.
    func challengePush(index: Int) -> Request<Void, EmbeddedAuthError>

    /// Polls for push notification approval.
    ///
    /// Call this method repeatedly at the interval given by ``NextAction/verifyOob(pollInMs:)`` until it returns
    /// ``Credentials`` (approved) or throws a terminal error (rejected or expired).
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    ///
    /// Requires an active session.
    func verifyOob() -> Request<Credentials, EmbeddedAuthError>

    /// Submits a recovery code to verify the user's identity.
    ///
    /// On success, the server rotates the recovery code and returns a ``NextAction/confirmRecoveryCode(newCode:)``
    /// continuation. Present `newCode` to the user, then call ``confirmRecoveryCode()`` to complete the flow.
    ///
    /// Requires an active session.
    ///
    /// - Parameter code: The recovery code entered by the user.
    func verifyRecoveryCode(_ code: String) -> Request<Void, EmbeddedAuthError>

    /// Confirms the user has recorded their rotated recovery code and completes the flow.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    ///
    /// Requires an active session.
    func confirmRecoveryCode() -> Request<Credentials, EmbeddedAuthError>

    /// Starts registering a new user.
    ///
    /// Call this when ``NextAction/signup(identifiers:)`` is among the `nextActions` and the user wants to create
    /// an account.
    ///
    /// The request always fails with ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)``:
    /// read its `nextActions` to find the next step of the registration (for example
    /// ``NextAction/identifyEmail`` or ``NextAction/verifyOTP(channel:identifier:)``) and handle it like any other
    /// continuation. Once the registration steps are complete the server offers ``NextAction/confirmSignup``,
    /// which you finish with ``confirmSignup()``.
    ///
    /// Requires an active session.
    ///
    /// - Note: If the server rejects the identifier before registration starts (for example, because of a
    ///   pre-registration validation), the request fails with ``EmbeddedAuthErrorReason/accessDenied`` and the flow
    ///   ends.
    func signup() -> Request<Void, EmbeddedAuthError>

    /// Confirms the registration and completes the flow.
    ///
    /// Call this when ``NextAction/confirmSignup`` is among the `nextActions`.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    ///
    /// Requires an active session. If the token exchange fails with ``EmbeddedAuthErrorReason/network``, the session is
    /// kept; retrying sends the confirmation again, and the server decides whether it can still be completed.
    func confirmSignup() -> Request<Credentials, EmbeddedAuthError>

    #if PASSKEYS_PLATFORM
    /// Submits a passkey assertion to sign the user in.
    ///
    /// Call this when ``NextAction/verifyPasskey(options:)`` is among the `nextActions`, after the user picked a
    /// passkey in the system UI built from ``PasskeyRequestOptions/assertionRequest()``. A passkey both identifies
    /// and verifies the user. Only discoverable passkeys are supported.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    /// If a second factor is also required, the request instead fails with
    /// ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)`` and the MFA actions in `nextActions`.
    ///
    /// If the passkey couldn't be verified, the request fails with
    /// ``EmbeddedAuthErrorReason/InsufficientAuthorization/invalidPasskey``. Show the passkey UI again with the new
    /// options found in `nextActions` (the previous assertion can't be reused), or offer another option. The server
    /// might not offer the passkey again, so look for ``NextAction/verifyPasskey(options:)`` before showing the UI.
    ///
    /// If the assertion has no user handle or lacks required data, the request fails locally with
    /// ``EmbeddedAuthErrorReason/invalidInput(_:)``: nothing is sent and the session is kept.
    ///
    /// Requires an active session, and the passkey must still be on offer: call this right after receiving a
    /// `nextActions` that contains ``NextAction/verifyPasskey(options:)``, before submitting any other step. If the
    /// request fails with ``EmbeddedAuthErrorReason/network``, the session is kept; retrying means passing the same
    /// assertion again, and the server decides whether it still accepts it.
    ///
    /// - Parameter passkey: The assertion obtained from `ASAuthorizationControllerDelegate`
    ///   (an `ASAuthorizationPlatformPublicKeyCredentialAssertion`).
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func verifyPasskey(_ passkey: any LoginPasskey) -> Request<Credentials, EmbeddedAuthError>
    #endif

}

public extension EmbeddedAuth {

    /// Starts a new embedded authorization flow targeting the given connection using all default capabilities and the default scope.
    func authorize(connection: String) -> Request<Void, EmbeddedAuthError> {
        authorize(connection: connection,
                  capabilities: EmbeddedCapability.all,
                  scope: "openid profile email offline_access",
                  audience: nil)
    }

    #if PASSKEYS_PLATFORM
    /// Default implementation of ``verifyPasskey(_:)`` for types outside the SDK that conform to ``EmbeddedAuth``.
    ///
    /// Sends no request: it fails with an ``EmbeddedAuthError`` whose ``EmbeddedAuthError/code`` is
    /// `a0.sdk.internal_error.not_implemented`. Implement ``verifyPasskey(_:)`` in your conforming type to support it.
    @available(iOS 16.6, macOS 13.5, visionOS 1.0, *)
    func verifyPasskey(_ passkey: any LoginPasskey) -> Request<Credentials, EmbeddedAuthError> {
        // The validator fails the request before any data task is created, so the session and URL are never used.
        Request(session: .shared,
                url: URL(fileURLWithPath: "/"),
                method: "POST",
                requestValidator: [EmbeddedAuthNotImplementedValidator(requirement: "verifyPasskey(_:)")],
                handle: { _, callback in
                    callback(.failure(EmbeddedAuthError(
                        info: ["error": notImplementedError,
                               "error_description": "verifyPasskey(_:) is not implemented by this EmbeddedAuth conformance."],
                        statusCode: 0
                    )))
                },
                logger: logger,
                auth0ClientInfo: auth0ClientInfo)
    }
    #endif
}
