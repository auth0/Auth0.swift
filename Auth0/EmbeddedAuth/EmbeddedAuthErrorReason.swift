import Foundation

/// Strongly-typed classification of an ``EmbeddedAuthError``.
///
/// Branch on ``EmbeddedAuthError/reason`` with an exhaustive `switch` to handle each case.
/// Only ``insufficientAuthorization(reason:nextActions:)`` is non-terminal; all other cases
/// mean the flow has ended and a new ``EmbeddedAuth/authorize(connection:)`` call is required
/// (except ``network`` and ``invalidInput(_:)``, where the same step can be tried again).
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

    /// Terminal: the push (out-of-band) challenge expired or could not be found. Restart the flow.
    case challengeExpired

    /// Terminal: the user explicitly denied the push notification. Restart the flow.
    case authorizationRejected

    /// Terminal: a second factor is required but the user has no eligible factor. Fall back to a redirect-based flow.
    case noEligibleFactors

    /// Terminal: consent is required but cannot be collected in the embedded flow.
    ///
    /// Complete sign-in with a redirect-based flow such as Universal Login.
    case consentRequired

    /// Terminal: no further action is available to continue the authorization.
    ///
    /// Start a new flow with ``EmbeddedAuth/authorize(connection:)``. If it keeps happening, check that the
    /// capabilities passed to ``EmbeddedAuth/authorize(connection:capabilities:scope:audience:)`` include a
    /// complete sign-in path, for example both ``EmbeddedCapability/identifyUsername`` and
    /// ``EmbeddedCapability/verifyPassword``.
    case noNextSteps

    /// Terminal: breached password detection blocked the login because the password appears in a data breach.
    ///
    /// The user has to choose a different password before signing in again.
    case passwordLeaked

    /// Terminal: access denied for a reason not modelled as its own case.
    ///
    /// Read ``EmbeddedAuthError/debugDescription`` for specifics.
    case accessDenied

    /// Terminal: the request was malformed (missing or invalid parameters).
    case invalidRequest

    /// Terminal: rate-limited by attack protection, such as brute-force protection.
    ///
    /// Suspicious IP throttling may instead be reported as ``ipBlocked``.
    case tooManyAttempts

    /// Terminal: rate-limited by same-user-login protection.
    case tooManyLogins

    /// Terminal: the device's IP address was rate-limited by suspicious IP throttling.
    ///
    /// The server returned `too_many_requests` with `error_description` `ip_blocked`. The session is
    /// cleared, so the same step cannot be retried; ask the user to try again later and start a new flow
    /// with ``EmbeddedAuth/authorize(connection:)``.
    case ipBlocked

    /// Terminal: the grant is no longer valid. Start a new flow with
    /// ``EmbeddedAuth/authorize(connection:)``.
    case sessionExpired

    /// The request never reached the server (network failure).
    ///
    /// The session is preserved — retrying the same step is safe. That includes the final token exchange of
    /// ``EmbeddedAuth/verifyOtp(_:type:)``, ``EmbeddedAuth/verifyPassword(_:)``, ``EmbeddedAuth/verifyOob()``,
    /// ``EmbeddedAuth/confirmRecoveryCode()``, ``EmbeddedAuth/confirmSignup()`` and `verifyPasskey(_:)`.
    /// The SDK doesn't keep a passkey assertion, so retrying `verifyPasskey(_:)` means passing the same assertion
    /// again; if the failure hit the token exchange, the server decides whether it still accepts it.
    case network

    /// Client-side guard: no flow is in progress.
    ///
    /// Call ``EmbeddedAuth/authorize(connection:)`` first.
    case noActiveSession

    /// Client-side guard: a local check on the input failed, so nothing was sent and the session is kept.
    ///
    /// The associated message says what to fix, for example a passkey without a user handle (only discoverable
    /// passkeys are supported). It never contains passkey data. Fix the input and call the same step again.
    case invalidInput(String)

    /// An error this SDK version does not classify.
    ///
    /// Read ``EmbeddedAuthError/code``, ``EmbeddedAuthError/debugDescription``, and
    /// ``EmbeddedAuthError/statusCode`` to diagnose.
    case unknown

    /// Sub-reasons carried by ``EmbeddedAuthErrorReason/insufficientAuthorization(reason:nextActions:)``.
    public enum InsufficientAuthorization: Sendable {

        /// A plain continuation: the server advanced the flow without a specific error.
        case none

        /// The one-time code or recovery code the user entered was incorrect, for a user the server has already
        /// identified. They may retry via `nextActions`.
        case invalidCode

        /// The identifier+code pair the user entered was incorrect. They may retry via `nextActions`.
        case invalidIdentifierOrCode

        /// The identifier (email, phone or username) or the password the user entered was rejected.
        /// They may retry via `nextActions`.
        case invalidIdentifierOrPassword

        /// The authorization is still pending — the user has not yet completed the out-of-band step.
        case authorizationPending

        /// The client is polling too frequently and should back off before retrying.
        case slowDown

        /// The passkey couldn't be verified.
        ///
        /// Show the passkey UI again with the new options from `nextActions` (the previous assertion can't be
        /// reused and the previous options must not be reused either), or offer another option from `nextActions`.
        /// The server doesn't say why verification failed.
        case invalidPasskey
    }
}
