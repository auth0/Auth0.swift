import Foundation

/// Strongly-typed classification of an ``EmbeddedAuthError``.
///
/// Branch on ``EmbeddedAuthError/reason`` with an exhaustive `switch` to handle each case.
/// Only ``insufficientAuthorization(reason:nextActions:)`` is non-terminal; all other cases
/// mean the flow has ended and a new ``EmbeddedAuth/authorize(connection:)`` call is required
/// (except ``network``, where retrying the same step is safe).
///
public enum EmbeddedAuthErrorReason: Sendable {

    /// Flow is non-terminal: the server returned `insufficient_authorization`.
    ///
    /// Act on one of `nextActions` to continue. The associated `reason` refines *why* the server
    /// still needs more — for example, ``InsufficientAuthorization/invalidCode`` when the user's
    /// last OTP was wrong but they may retry.
    ///
    /// - Parameters:
    ///   - reason:      The specific `insufficient_authorization` sub-reason, or
    ///     ``InsufficientAuthorization/none`` for a plain continuation with no error.
    ///   - nextActions: The actions the caller may take to continue the flow.
    case insufficientAuthorization(reason: InsufficientAuthorization, nextActions: [NextAction])

    /// Terminal: too many wrong OTP submissions. Restart the flow.
    case tooManyWrongOtpAttempts

    /// Terminal: the OTP challenge expired before it was verified. Restart the flow.
    case challengeExpired

    /// Terminal: the user rejected or cancelled the push notification. Restart the flow.
    case authorizationRejected

    /// Terminal: no eligible MFA factors are enrolled. Enrol a factor and restart the flow.
    case noEligibleFactors

    /// Terminal: access denied for a reason not modelled as its own case.
    ///
    /// Read ``EmbeddedAuthError/debugDescription`` for specifics.
    case accessDenied

    /// Terminal: the request was malformed (missing or invalid parameters).
    case invalidRequest

    /// Terminal: rate-limited by attack-protection (BFP / SIPT).
    case tooManyAttempts

    /// Terminal: rate-limited by same-user-login protection.
    case tooManyLogins

    /// Terminal: the grant is no longer valid. Start a new flow with
    /// ``EmbeddedAuth/authorize(connection:)``.
    case sessionExpired

    /// The request never reached the server (network failure).
    ///
    /// The session is preserved — retrying the same step is safe.
    case network

    /// Client-side guard: no flow is in progress.
    ///
    /// Call ``EmbeddedAuth/authorize(connection:)`` first.
    case noActiveSession

    /// An error this SDK version does not classify.
    ///
    /// Read ``EmbeddedAuthError/code``, ``EmbeddedAuthError/debugDescription``, and
    /// ``EmbeddedAuthError/statusCode`` to diagnose.
    case unknown

    /// Sub-reasons carried by ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)``.
    public enum InsufficientAuthorization: Sendable {

        /// A plain continuation: the server advanced the flow without a specific error.
        case none

        /// The OTP the user entered was incorrect. They may retry via `nextActions`.
        case invalidCode

        /// The identifier+code pair the user entered was incorrect. They may retry via `nextActions`.
        case invalidIdentifierOrCode

        /// The authorization is still pending — the user has not yet completed the out-of-band step.
        case authorizationPending

        /// The client is polling too frequently and should back off before retrying.
        case slowDown
    }
}
