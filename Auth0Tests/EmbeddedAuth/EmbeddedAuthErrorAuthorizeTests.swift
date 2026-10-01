import Testing
import Foundation
@testable import Auth0

@Suite struct EmbeddedAuthErrorAuthorizeTests {

    // MARK: - kind type-check (added in Task 1)

    @Test func embeddedAuthErrorKindTypeExists() {
        let _: EmbeddedAuthErrorKind = .unknown
    }

    // MARK: - kind: insufficientAuthorization

    @Test func kindIsInsufficientAuthorizationForCorrectCode() {
        let error = EmbeddedAuthError(info: ["error": "insufficient_authorization"], statusCode: 403)
        guard case .insufficientAuthorization = error.reason else {
            Issue.record("Expected .insufficientAuthorization, got \(error.reason)"); return
        }
    }

    @Test func kindInsufficientAuthorizationParsesIdentifyEmail() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:identify:email:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.identifyEmail])
    }

    @Test func kindInsufficientAuthorizationParsesChallengeEmail() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1", "index": 2, "identifier": "al**@example.com"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason,
              case .challengeEmail(let index, let id) = actions.first else {
            Issue.record("Expected .challengeEmail"); return
        }
        #expect(index == 2)
        #expect(id == "al**@example.com")
    }

    @Test func kindInsufficientAuthorizationDropsChallengeEmailMissingIndex() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1", "identifier": "al**@example.com"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func kindInsufficientAuthorizationDropsChallengeEmailMissingIdentifier() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1", "index": 1]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func kindInsufficientAuthorizationDropsChallengeEmailMissingBothFields() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func kindInsufficientAuthorizationParsesVerifyOTPWithChannelAndIdentifier() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason,
              case .verifyOTP(let channel, let id) = actions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == .email)
        #expect(id == "al**@example.com")
    }

    @Test func kindInsufficientAuthorizationParsesVerifyOTPChannelCaseInsensitively() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "EMAIL"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason,
              case .verifyOTP(let channel, _) = actions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == .email)
    }

    @Test func kindInsufficientAuthorizationDropsVerifyOTPWhenChannelAbsent() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func kindInsufficientAuthorizationDropsVerifyOTPWhenChannelUnknown() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "carrier_pigeon"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func kindInsufficientAuthorizationDecodesSmsChannel() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "sms"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason,
              case .verifyOTP(let channel, _) = actions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == .sms)
    }

    @Test func kindInsufficientAuthorizationDecodesUnknownAction() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:future:v99"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason,
              case .unknown(let raw) = actions.first else {
            Issue.record("Expected .unknown action"); return
        }
        #expect(raw == "action:future:v99")
    }

    @Test func kindInsufficientAuthorizationYieldsEmptyActionsWhenNextKeyAbsent() {
        let error = EmbeddedAuthError(info: ["error": "insufficient_authorization"], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func kindInsufficientAuthorizationDecodesMultipleActions() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [
                ["action": "action:identify:email:v1"],
                ["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]
            ]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.count == 2)
        #expect(actions[0] == .identifyEmail)
        #expect(actions[1] == .challengeEmail(index: 0, identifier: "al**@example.com"))
    }

    // MARK: - reason: invalidCode

    @Test func reasonIsInvalidCodeForInvalidCodeUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "invalid_code"],
            statusCode: 403
        )
        guard case .invalidCode = error.reason else {
            Issue.record("Expected .invalidCode, got \(error.reason)"); return
        }
    }

    @Test func reasonIsInvalidCodeForInvalidIdentifierOrCodeUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "invalid_identifier_or_code"],
            statusCode: 403
        )
        guard case .invalidCode = error.reason else {
            Issue.record("Expected .invalidCode, got \(error.reason)"); return
        }
    }

    @Test func reasonIsInvalidCodeForInvalidCodeUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "invalid_code"],
            statusCode: 403
        )
        guard case .invalidCode = error.reason else {
            Issue.record("Expected .invalidCode, got \(error.reason)"); return
        }
    }

    @Test func reasonIsInvalidCodeForInvalidIdentifierOrCodeUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "invalid_identifier_or_code"],
            statusCode: 403
        )
        guard case .invalidCode = error.reason else {
            Issue.record("Expected .invalidCode, got \(error.reason)"); return
        }
    }

    @Test func reasonInvalidCodeHasPriorityOverAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "invalid_code"],
            statusCode: 403
        )
        if case .accessDenied = error.reason {
            Issue.record("invalid_code must map to .invalidCode, not .accessDenied")
        }
    }

    // MARK: - reason: invalidIdentifierOrPassword

    @Test func reasonIsInvalidIdentifierOrPasswordForMatchingDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "invalid_identifier_or_password"],
            statusCode: 403
        )
        guard case .invalidIdentifierOrPassword = error.reason else {
            Issue.record("Expected .invalidIdentifierOrPassword, got \(error.reason)"); return
        }
    }

    // MARK: - reason: authorizationPending

    @Test func reasonIsAuthorizationPendingForMatchingDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "authorization_pending"],
            statusCode: 403
        )
        guard case .authorizationPending = error.reason else {
            Issue.record("Expected .authorizationPending, got \(error.reason)"); return
        }
    }

    // MARK: - reason: slowDown

    @Test func reasonIsSlowDownForMatchingDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "slow_down"],
            statusCode: 403
        )
        guard case .slowDown = error.reason else {
            Issue.record("Expected .slowDown, got \(error.reason)"); return
        }
    }

    @Test func reasonInsufficientAuthorizationStillCatchesUnclassifiedDescriptions() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "some_future_description"],
            statusCode: 403
        )
        guard case .insufficientAuthorization = error.reason else {
            Issue.record("Expected .insufficientAuthorization for unknown description, got \(error.reason)"); return
        }
    }

    // MARK: - reason: invalidRequest

    @Test func reasonIsInvalidRequestForInvalidRequestCode() {
        let error = EmbeddedAuthError(
            info: ["error": "invalid_request", "error_description": "Missing required parameter."],
            statusCode: 400
        )
        guard case .invalidRequest = error.reason else {
            Issue.record("Expected .invalidRequest, got \(error.reason)"); return
        }
    }

    // MARK: - reason: access_denied variants

    @Test func kindIsTooManyWrongOtpAttemptsWhenBothFieldsMatch() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "too_many_wrong_otp_attempts"],
            statusCode: 403
        )
        guard case .tooManyWrongOtpAttempts = error.reason else {
            Issue.record("Expected .tooManyWrongOtpAttempts, got \(error.reason)"); return
        }
    }

    @Test func kindIsChallengeExpiredWhenBothFieldsMatch() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "challenge_expired"],
            statusCode: 403
        )
        guard case .challengeExpired = error.reason else {
            Issue.record("Expected .challengeExpired, got \(error.reason)"); return
        }
    }

    @Test func kindIsAccessDeniedForOtherAccessDeniedDescriptions() {
        for desc in ["consent_required", "no_next_steps", "authorization_rejected", "no_eligible_factors"] {
            let error = EmbeddedAuthError(
                info: ["error": "access_denied", "error_description": desc],
                statusCode: 403
            )
            guard case .accessDenied = error.reason else {
                Issue.record("Expected .accessDenied for desc '\(desc)', got \(error.reason)"); return
            }
        }
    }

    @Test func kindIsAccessDeniedWhenNoDescription() {
        let error = EmbeddedAuthError(info: ["error": "access_denied"], statusCode: 403)
        guard case .accessDenied = error.reason else {
            Issue.record("Expected .accessDenied, got \(error.reason)"); return
        }
    }

    // Ordering guard: too_many_wrong_otp_attempts must NOT fall through to .accessDenied
    @Test func kindTooManyWrongOtpAttemptsHasPriorityOverAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "too_many_wrong_otp_attempts"],
            statusCode: 403
        )
        if case .accessDenied = error.reason {
            Issue.record("too_many_wrong_otp_attempts must map to .tooManyWrongOtpAttempts, not .accessDenied")
        }
    }

    // Ordering guard: challenge_expired must NOT fall through to .accessDenied
    @Test func kindChallengeExpiredHasPriorityOverAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "challenge_expired"],
            statusCode: 403
        )
        if case .accessDenied = error.reason {
            Issue.record("challenge_expired must map to .challengeExpired, not .accessDenied")
        }
    }

    // MARK: - kind: too_many_requests variants

    @Test func kindIsTooManyAttemptsFor429AndCorrectDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 429
        )
        guard case .tooManyAttempts = error.reason else {
            Issue.record("Expected .tooManyAttempts, got \(error.reason)"); return
        }
    }

    @Test func kindIsTooManyLoginsFor429AndCorrectDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_logins"],
            statusCode: 429
        )
        guard case .tooManyLogins = error.reason else {
            Issue.record("Expected .tooManyLogins, got \(error.reason)"); return
        }
    }

    @Test func kindIsUnknownFor429TooManyRequestsWithWrongStatusCode() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 400   // wrong status code
        )
        guard case .unknown = error.reason else {
            Issue.record("Expected .unknown for wrong statusCode, got \(error.reason)"); return
        }
    }

    // MARK: - kind: sessionExpired

    @Test func kindIsSessionExpiredForInvalidGrant() {
        let error = EmbeddedAuthError(
            info: ["error": "invalid_grant", "error_description": "The auth_session has expired."],
            statusCode: 400
        )
        guard case .sessionExpired = error.reason else {
            Issue.record("Expected .sessionExpired, got \(error.reason)"); return
        }
    }

    // MARK: - kind: noActiveSession

    @Test func kindIsNoActiveSessionForSyntheticCode() {
        let error = EmbeddedAuthError(
            info: ["error": "no_active_session", "error_description": "No active embedded auth session."],
            statusCode: 0
        )
        guard case .noActiveSession = error.reason else {
            Issue.record("Expected .noActiveSession, got \(error.reason)"); return
        }
    }

    // MARK: - kind: network

    @Test func kindIsNetworkForURLError() {
        let error = EmbeddedAuthError(cause: URLError(.notConnectedToInternet), statusCode: 0)
        guard case .network = error.reason else {
            Issue.record("Expected .network, got \(error.reason)"); return
        }
    }

    @Test func kindIsNetworkForTimedOutError() {
        let error = EmbeddedAuthError(cause: URLError(.timedOut), statusCode: 0)
        guard case .network = error.reason else {
            Issue.record("Expected .network, got \(error.reason)"); return
        }
    }

    // MARK: - kind: unknown

    @Test func kindIsUnknownForUnrecognisedCode() {
        let error = EmbeddedAuthError(
            info: ["error": "server_error", "error_description": "Something went wrong."],
            statusCode: 500
        )
        guard case .unknown = error.reason else {
            Issue.record("Expected .unknown, got \(error.reason)"); return
        }
    }

    @Test func reasonIsUnknownForUnclassifiedServerError() {
        let error = EmbeddedAuthError(
            info: ["error": "server_error", "error_description": "Something else."],
            statusCode: 503
        )
        guard case .unknown = error.reason else {
            Issue.record("Expected .unknown, got \(error.reason)"); return
        }
    }
}
