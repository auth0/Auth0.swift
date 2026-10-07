import Foundation

// MARK: - Result alias

/// `Result` wrapper for Embedded Login operations.
public typealias EmbeddedAuthResult<T> = Result<T, EmbeddedAuthError>

// MARK: - IdentifierType

/// The type of identifier a user submits during the identify step.
public enum IdentifierType {
    /// An email address.
    case email
    /// A phone number.
    case phone
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
    ///   - identifier: The identifier value (e.g. an email address).
    ///   - type: The type of identifier being submitted.
    func identify(_ identifier: String, type: IdentifierType) -> Request<Void, EmbeddedAuthError>

    /// Requests that the server send an email OTP challenge.
    ///
    /// Requires an active session.
    /// - Parameter index: The zero-based index of the `challengeEmail` entry from the
    ///   `nextActions` associated value of ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)``.
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

    /// Requests that the server send a phone OTP challenge via SMS or voice.
    ///
    /// Requires an active session.
    ///
    /// - Parameters:
    ///   - index:          Zero-based index of the `challengePhone` entry from the `nextActions` list.
    ///   - deliveryMethod: Whether to deliver the code via SMS or voice call.
    func challengePhone(index: Int, deliveryMethod: PhoneDeliveryMethod) -> Request<Void, EmbeddedAuthError>

    /// Requests that the server send a push notification to the user's enrolled device.
    ///
    /// Poll the result with ``verifyOob()`` at the interval specified by ``NextAction/verifyOob(pollInMs:)``.
    ///
    /// Requires an active session.
    ///
    /// - Parameter index: Zero-based index of the `challengePush` entry from the `nextActions` list.
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

}

public extension EmbeddedAuth {

    /// Starts a new embedded authorization flow targeting the given connection using all default capabilities and the default scope.
    func authorize(connection: String) -> Request<Void, EmbeddedAuthError> {
        authorize(connection: connection,
                  capabilities: EmbeddedCapability.all,
                  scope: "openid profile email offline_access",
                  audience: nil)
    }
}
