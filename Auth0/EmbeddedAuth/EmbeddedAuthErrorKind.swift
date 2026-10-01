import Foundation

/// Strongly-typed classification of an ``EmbeddedAuthError``.
///
/// Branch on ``EmbeddedAuthError/kind`` with an exhaustive `switch` to handle each case.
/// Only ``insufficientAuthorization(nextActions:)`` is non-terminal; all other cases
/// mean the flow has ended and a new ``EmbeddedAuth/authorize(connection:)`` call is required
/// (except ``network``, where retrying the same step is safe).
///
/// > Note: Discovery-layer errors (`isFeatureDisabled`) are not covered here;
/// > they remain as dedicated properties on ``EmbeddedAuthError``.
public enum EmbeddedAuthErrorKind: Sendable {

    /// Flow is non-terminal; act on one of `nextActions` to continue.
    case insufficientAuthorization(nextActions: [NextAction])

    /// Terminal: too many wrong OTP submissions. Restart the flow.
    case tooManyWrongOtpAttempts

    /// Terminal: the OTP challenge expired before it was verified. Restart the flow.
    case challengeExpired

    /// Terminal: access denied for a reason not modelled as its own case.
    ///
    /// Read ``EmbeddedAuthError/debugDescription`` for specifics.
    case accessDenied

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
}
