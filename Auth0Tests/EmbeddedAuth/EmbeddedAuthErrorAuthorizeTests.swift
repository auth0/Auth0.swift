import Testing
import Foundation
@testable import Auth0

@Suite struct EmbeddedAuthErrorAuthorizeTests {

    // MARK: - reason type-check

    @Test func embeddedAuthErrorReasonTypeExists() {
        let _: EmbeddedAuthErrorReason = .unknown
    }

    // MARK: - reason: insufficientAuthorization (nextActions parsing)

    @Test func reasonIsInsufficientAuthorizationForCorrectCode() {
        let error = EmbeddedAuthError(info: ["error": "insufficient_authorization"], statusCode: 403)
        guard case .insufficientAuthorization(.none, _) = error.reason else {
            Issue.record("Expected .insufficientAuthorization(.none, _), got \(error.reason)"); return
        }
    }

    @Test func reasonInsufficientAuthorizationParsesIdentifyEmail() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:identify:email:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.identifyEmail])
    }

    @Test func reasonInsufficientAuthorizationParsesChallengeEmail() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1", "index": 2, "identifier": "al**@example.com"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .challengeEmail(let index, let id) = actions.first else {
            Issue.record("Expected .challengeEmail"); return
        }
        #expect(index == 2)
        #expect(id == "al**@example.com")
    }

    @Test func reasonInsufficientAuthorizationDropsChallengeEmailMissingIndex() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1", "identifier": "al**@example.com"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonInsufficientAuthorizationDropsChallengeEmailMissingIdentifier() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1", "index": 1]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonInsufficientAuthorizationDropsChallengeEmailMissingBothFields() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonInsufficientAuthorizationParsesVerifyOTPWithChannelAndIdentifier() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .verifyOTP(let channel, let id) = actions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == .email)
        #expect(id == "al**@example.com")
    }

    @Test func reasonInsufficientAuthorizationParsesVerifyOTPChannelCaseInsensitively() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "EMAIL"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .verifyOTP(let channel, _) = actions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == .email)
    }

    @Test func reasonInsufficientAuthorizationDropsVerifyOTPWhenChannelAbsent() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonInsufficientAuthorizationDropsVerifyOTPWhenChannelUnknown() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "carrier_pigeon"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonInsufficientAuthorizationDecodesSmsChannel() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "sms"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .verifyOTP(let channel, _) = actions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == .sms)
    }

    @Test func reasonInsufficientAuthorizationDecodesUnknownAction() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:future:v99"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .unknown(let raw) = actions.first else {
            Issue.record("Expected .unknown action"); return
        }
        #expect(raw == "action:future:v99")
    }

    @Test func reasonInsufficientAuthorizationYieldsEmptyActionsWhenNextKeyAbsent() {
        let error = EmbeddedAuthError(info: ["error": "insufficient_authorization"], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonInsufficientAuthorizationDecodesMultipleActions() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [
                ["action": "action:identify:email:v1"],
                ["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]
            ]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.count == 2)
        #expect(actions[0] == .identifyEmail)
        #expect(actions[1] == .challengeEmail(index: 0, identifier: "al**@example.com"))
    }

    // MARK: - reason: insufficientAuthorization sub-reasons

    @Test func reasonIsInvalidCodeUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "invalid_code"],
            statusCode: 403
        )
        guard case .insufficientAuthorization(.invalidCode, _) = error.reason else {
            Issue.record("Expected .insufficientAuthorization(.invalidCode, _), got \(error.reason)"); return
        }
    }

    @Test func reasonIsInvalidIdentifierOrCodeUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "invalid_identifier_or_code"],
            statusCode: 403
        )
        guard case .insufficientAuthorization(.invalidIdentifierOrCode, _) = error.reason else {
            Issue.record("Expected .insufficientAuthorization(.invalidIdentifierOrCode, _), got \(error.reason)"); return
        }
    }

    @Test func reasonIsAuthorizationPendingUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "authorization_pending"],
            statusCode: 403
        )
        guard case .insufficientAuthorization(.authorizationPending, _) = error.reason else {
            Issue.record("Expected .insufficientAuthorization(.authorizationPending, _), got \(error.reason)"); return
        }
    }

    @Test func reasonIsSlowDownUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "slow_down"],
            statusCode: 403
        )
        guard case .insufficientAuthorization(.slowDown, _) = error.reason else {
            Issue.record("Expected .insufficientAuthorization(.slowDown, _), got \(error.reason)"); return
        }
    }

    @Test func reasonIsInvalidIdentifierOrPasswordUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "invalid_identifier_or_password"],
            statusCode: 403
        )
        guard case .insufficientAuthorization(.invalidIdentifierOrPassword, _) = error.reason else {
            Issue.record("Expected .insufficientAuthorization(.invalidIdentifierOrPassword, _), got \(error.reason)"); return
        }
    }

    @Test func reasonIsNoneForUnclassifiedInsufficientAuthorizationDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "some_future_description"],
            statusCode: 403
        )
        guard case .insufficientAuthorization(.none, _) = error.reason else {
            Issue.record("Expected .insufficientAuthorization(.none, _), got \(error.reason)"); return
        }
    }

    // A sub-reason and nextActions are carried together: a wrong OTP still ships retry actions.
    @Test func reasonCarriesSubReasonAndNextActionsTogether() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "error_description": "invalid_code",
            "next": [["action": "action:verify:otp:v1", "channel": "email"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(.invalidCode, let actions) = error.reason,
              case .verifyOTP(let channel, _) = actions.first else {
            Issue.record("Expected .invalidCode with a verifyOTP action, got \(error.reason)"); return
        }
        #expect(channel == .email)
    }

    // MARK: - reason: access_denied

    @Test func reasonIsTooManyWrongOtpAttemptsUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "too_many_wrong_otp_attempts"],
            statusCode: 403
        )
        guard case .tooManyWrongOtpAttempts = error.reason else {
            Issue.record("Expected .tooManyWrongOtpAttempts, got \(error.reason)"); return
        }
    }

    @Test func reasonIsChallengeExpiredUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "challenge_expired"],
            statusCode: 403
        )
        guard case .challengeExpired = error.reason else {
            Issue.record("Expected .challengeExpired, got \(error.reason)"); return
        }
    }

    @Test func reasonIsAccessDeniedForOtherDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "some_future_denial"],
            statusCode: 403
        )
        guard case .accessDenied = error.reason else {
            Issue.record("Expected .accessDenied for other access_denied description, got \(error.reason)"); return
        }
    }

    @Test func reasonIsAccessDeniedWithoutDescription() {
        let error = EmbeddedAuthError(info: ["error": "access_denied"], statusCode: 403)
        guard case .accessDenied = error.reason else {
            Issue.record("Expected .accessDenied for access_denied without description, got \(error.reason)"); return
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

    // MARK: - reason: too_many_requests variants

    @Test func reasonIsTooManyAttemptsFor429AndCorrectDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 429
        )
        guard case .tooManyAttempts = error.reason else {
            Issue.record("Expected .tooManyAttempts, got \(error.reason)"); return
        }
    }

    @Test func reasonIsTooManyLoginsFor429AndCorrectDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_logins"],
            statusCode: 429
        )
        guard case .tooManyLogins = error.reason else {
            Issue.record("Expected .tooManyLogins, got \(error.reason)"); return
        }
    }

    @Test func reasonIsUnknownFor429TooManyRequestsWithWrongStatusCode() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 400   // wrong status code
        )
        guard case .unknown = error.reason else {
            Issue.record("Expected .unknown for wrong statusCode, got \(error.reason)"); return
        }
    }

    // MARK: - reason: sessionExpired

    @Test func reasonIsSessionExpiredForInvalidGrant() {
        let error = EmbeddedAuthError(
            info: ["error": "invalid_grant", "error_description": "The auth_session has expired."],
            statusCode: 400
        )
        guard case .sessionExpired = error.reason else {
            Issue.record("Expected .sessionExpired, got \(error.reason)"); return
        }
    }

    // MARK: - reason: noActiveSession

    @Test func reasonIsNoActiveSessionForSyntheticCode() {
        let error = EmbeddedAuthError(
            info: ["error": "no_active_session", "error_description": "No active embedded auth session."],
            statusCode: 0
        )
        guard case .noActiveSession = error.reason else {
            Issue.record("Expected .noActiveSession, got \(error.reason)"); return
        }
    }

    // MARK: - reason: network

    @Test func reasonIsNetworkForURLError() {
        let error = EmbeddedAuthError(cause: URLError(.notConnectedToInternet), statusCode: 0)
        guard case .network = error.reason else {
            Issue.record("Expected .network, got \(error.reason)"); return
        }
    }

    @Test func reasonIsNetworkForTimedOutError() {
        let error = EmbeddedAuthError(cause: URLError(.timedOut), statusCode: 0)
        guard case .network = error.reason else {
            Issue.record("Expected .network, got \(error.reason)"); return
        }
    }

    // MARK: - reason: unknown

    @Test func reasonIsUnknownForUnrecognisedCode() {
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
