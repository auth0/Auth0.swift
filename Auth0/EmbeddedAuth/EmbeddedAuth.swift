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
    /// Call this when ``NextAction/signup(identifiers:passwordRequirement:)`` is among the `nextActions` and the user
    /// wants to create an account.
    ///
    /// The request always fails with ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)``:
    /// read its `nextActions` to find the next step of the registration (for example
    /// ``NextAction/identifyEmail`` or ``NextAction/verifyOTP(channel:identifier:)``) and handle it like any other
    /// continuation. Once the registration steps are complete the server offers
    /// ``NextAction/confirmSignup(password:)``, which you finish with ``confirmSignup()`` or ``confirmSignup(password:)``.
    ///
    /// Requires an active session.
    ///
    /// - Note: If the server rejects the identifier before registration starts (for example, because of a
    ///   pre-registration validation), the request fails with ``EmbeddedAuthErrorReason/accessDenied`` and the flow
    ///   ends.
    func signup() -> Request<Void, EmbeddedAuthError>

    /// Confirms the registration without a password and completes the flow.
    ///
    /// Call this when ``NextAction/confirmSignup(password:)`` is among the `nextActions` and its `password` is `nil`
    /// (the connection does not collect one), or when the password is optional and the user skips it. It is equivalent
    /// to ``confirmSignup(password:)`` with `nil`.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    ///
    /// Requires an active session. If the token exchange fails with ``EmbeddedAuthErrorReason/network``, the session is
    /// kept; retrying sends the confirmation again, and the server decides whether it can still be completed.
    ///
    /// If the connection requires a password, the request fails with
    /// ``EmbeddedAuthErrorReason/InsufficientAuthorization/passwordRequired`` and the flow stays open.
    func confirmSignup() -> Request<Credentials, EmbeddedAuthError>

    /// Confirms the registration, optionally with a password for the new account, and completes the flow.
    ///
    /// Call this when ``NextAction/confirmSignup(password:)`` is among the `nextActions`. Pass the password the user
    /// entered, or `nil` to create the account without one when the password is optional.
    ///
    /// The password is sent as given: it is not trimmed, and an empty string is sent as an empty string. The SDK does not
    /// check its length or its complexity locally. The server is authoritative; a password longer than 2048 characters
    /// ends the flow with ``EmbeddedAuthErrorReason/invalidRequest``.
    ///
    /// On success, exchanges the returned authorization code for ``Credentials`` internally and returns them directly.
    /// The SDK never keeps the password. If the token exchange fails with ``EmbeddedAuthErrorReason/network``, the
    /// session is kept; retrying sends the confirmation again, so pass the password again.
    ///
    /// A request the server cannot accept yet fails with
    /// ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)`` and the flow stays open:
    /// - ``EmbeddedAuthErrorReason/InsufficientAuthorization/passwordRequired``: ask for a password.
    /// - ``EmbeddedAuthErrorReason/InsufficientAuthorization/passwordNotAccepted``: the connection does not collect one;
    ///   call ``confirmSignup()``.
    /// - ``EmbeddedAuthErrorReason/InsufficientAuthorization/invalidPassword``: the password does not meet the
    ///   connection's policy; ask for another one.
    ///
    /// A password found in a data breach ends the flow with ``EmbeddedAuthErrorReason/passwordLeaked``.
    ///
    /// Requires an active session.
    ///
    /// - Note: Types outside the SDK that conform to ``EmbeddedAuth`` get a default implementation. It forwards `nil` to
    ///   ``confirmSignup()``; for a password it sends no request and fails with an ``EmbeddedAuthError`` whose
    ///   ``EmbeddedAuthError/code`` is `a0.sdk.internal_error.not_implemented`.
    ///
    /// - Parameter password: The password entered by the user, or `nil` for none.
    func confirmSignup(password: String?) -> Request<Credentials, EmbeddedAuthError>

}

public extension EmbeddedAuth {

    /// Starts a new embedded authorization flow targeting the given connection using all default capabilities and the default scope.
    func authorize(connection: String) -> Request<Void, EmbeddedAuthError> {
        authorize(connection: connection,
                  capabilities: EmbeddedCapability.all,
                  scope: "openid profile email offline_access",
                  audience: nil)
    }

    /// Default implementation of ``confirmSignup(password:)`` for types outside the SDK that conform to ``EmbeddedAuth``.
    ///
    /// The client returned by ``Auth0/embeddedAuth(clientId:domain:session:)`` implements this method. This default
    /// forwards `nil` to ``confirmSignup()``. For a password it sends no request: the returned request fails with an
    /// ``EmbeddedAuthError`` whose ``EmbeddedAuthError/code`` is `a0.sdk.internal_error.not_implemented`. Implement the
    /// method in your conforming type to support it.
    ///
    /// - Parameter password: The password entered by the user, or `nil` for none.
    /// - Returns: The request of ``confirmSignup()`` for `nil`, otherwise a request that fails locally.
    func confirmSignup(password: String?) -> Request<Credentials, EmbeddedAuthError> {
        guard password != nil else { return confirmSignup() }
        return Request(
            // The validator throws before a data task is created, so the session and the URL are never used.
            session: .shared,
            url: URL(fileURLWithPath: "/e/authorize"),
            method: "POST",
            requestValidator: [EmbeddedAuthNotImplementedValidator(requirement: "confirmSignup(password:)")],
            handle: { _, callback in
                callback(.failure(EmbeddedAuthError.notImplemented(requirement: "confirmSignup(password:)")))
            },
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

}
