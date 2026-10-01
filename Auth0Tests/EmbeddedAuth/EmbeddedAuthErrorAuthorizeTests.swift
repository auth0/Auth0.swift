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
        guard case .insufficientAuthorization = error.kind else {
            Issue.record("Expected .insufficientAuthorization, got \(error.kind)"); return
        }
    }

    @Test func kindInsufficientAuthorizationParsesIdentifyEmail() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:identify:email:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.kind else {
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
        guard case .insufficientAuthorization(let actions) = error.kind,
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
        guard case .insufficientAuthorization(let actions) = error.kind else {
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
        guard case .insufficientAuthorization(let actions) = error.kind else {
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
        guard case .insufficientAuthorization(let actions) = error.kind else {
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
        guard case .insufficientAuthorization(let actions) = error.kind,
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
        guard case .insufficientAuthorization(let actions) = error.kind,
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
        guard case .insufficientAuthorization(let actions) = error.kind else {
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
        guard case .insufficientAuthorization(let actions) = error.kind else {
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
        guard case .insufficientAuthorization(let actions) = error.kind,
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
        guard case .insufficientAuthorization(let actions) = error.kind,
              case .unknown(let raw) = actions.first else {
            Issue.record("Expected .unknown action"); return
        }
        #expect(raw == "action:future:v99")
    }

    @Test func kindInsufficientAuthorizationYieldsEmptyActionsWhenNextKeyAbsent() {
        let error = EmbeddedAuthError(info: ["error": "insufficient_authorization"], statusCode: 403)
        guard case .insufficientAuthorization(let actions) = error.kind else {
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
        guard case .insufficientAuthorization(let actions) = error.kind else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.count == 2)
        #expect(actions[0] == .identifyEmail)
        #expect(actions[1] == .challengeEmail(index: 0, identifier: "al**@example.com"))
    }

    // MARK: - kind: access_denied variants

    @Test func kindIsTooManyWrongOtpAttemptsWhenBothFieldsMatch() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "too_many_wrong_otp_attempts"],
            statusCode: 403
        )
        guard case .tooManyWrongOtpAttempts = error.kind else {
            Issue.record("Expected .tooManyWrongOtpAttempts, got \(error.kind)"); return
        }
    }

    @Test func kindIsChallengeExpiredWhenBothFieldsMatch() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "challenge_expired"],
            statusCode: 403
        )
        guard case .challengeExpired = error.kind else {
            Issue.record("Expected .challengeExpired, got \(error.kind)"); return
        }
    }

    @Test func kindIsAccessDeniedForOtherAccessDeniedDescriptions() {
        for desc in ["consent_required", "no_next_steps", "authorization_rejected", "no_eligible_factors"] {
            let error = EmbeddedAuthError(
                info: ["error": "access_denied", "error_description": desc],
                statusCode: 403
            )
            guard case .accessDenied = error.kind else {
                Issue.record("Expected .accessDenied for desc '\(desc)', got \(error.kind)"); return
            }
        }
    }

    @Test func kindIsAccessDeniedWhenNoDescription() {
        let error = EmbeddedAuthError(info: ["error": "access_denied"], statusCode: 403)
        guard case .accessDenied = error.kind else {
            Issue.record("Expected .accessDenied, got \(error.kind)"); return
        }
    }

    // Ordering guard: too_many_wrong_otp_attempts must NOT fall through to .accessDenied
    @Test func kindTooManyWrongOtpAttemptsHasPriorityOverAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "too_many_wrong_otp_attempts"],
            statusCode: 403
        )
        if case .accessDenied = error.kind {
            Issue.record("too_many_wrong_otp_attempts must map to .tooManyWrongOtpAttempts, not .accessDenied")
        }
    }

    // Ordering guard: challenge_expired must NOT fall through to .accessDenied
    @Test func kindChallengeExpiredHasPriorityOverAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "challenge_expired"],
            statusCode: 403
        )
        if case .accessDenied = error.kind {
            Issue.record("challenge_expired must map to .challengeExpired, not .accessDenied")
        }
    }

    // MARK: - kind: too_many_requests variants

    @Test func kindIsTooManyAttemptsFor429AndCorrectDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 429
        )
        guard case .tooManyAttempts = error.kind else {
            Issue.record("Expected .tooManyAttempts, got \(error.kind)"); return
        }
    }

    @Test func kindIsTooManyLoginsFor429AndCorrectDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_logins"],
            statusCode: 429
        )
        guard case .tooManyLogins = error.kind else {
            Issue.record("Expected .tooManyLogins, got \(error.kind)"); return
        }
    }

    @Test func kindIsUnknownFor429TooManyRequestsWithWrongStatusCode() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 400   // wrong status code
        )
        guard case .unknown = error.kind else {
            Issue.record("Expected .unknown for wrong statusCode, got \(error.kind)"); return
        }
    }

    // MARK: - kind: sessionExpired

    @Test func kindIsSessionExpiredForInvalidGrant() {
        let error = EmbeddedAuthError(
            info: ["error": "invalid_grant", "error_description": "The auth_session has expired."],
            statusCode: 400
        )
        guard case .sessionExpired = error.kind else {
            Issue.record("Expected .sessionExpired, got \(error.kind)"); return
        }
    }

    // MARK: - kind: noActiveSession

    @Test func kindIsNoActiveSessionForSyntheticCode() {
        let error = EmbeddedAuthError(
            info: ["error": "no_active_session", "error_description": "No active embedded auth session."],
            statusCode: 0
        )
        guard case .noActiveSession = error.kind else {
            Issue.record("Expected .noActiveSession, got \(error.kind)"); return
        }
    }

    // MARK: - kind: network

    @Test func kindIsNetworkForURLError() {
        let error = EmbeddedAuthError(cause: URLError(.notConnectedToInternet), statusCode: 0)
        guard case .network = error.kind else {
            Issue.record("Expected .network, got \(error.kind)"); return
        }
    }

    @Test func kindIsNetworkForTimedOutError() {
        let error = EmbeddedAuthError(cause: URLError(.timedOut), statusCode: 0)
        guard case .network = error.kind else {
            Issue.record("Expected .network, got \(error.kind)"); return
        }
    }

    // MARK: - kind: unknown

    @Test func kindIsUnknownForUnrecognisedCode() {
        let error = EmbeddedAuthError(
            info: ["error": "server_error", "error_description": "Something went wrong."],
            statusCode: 500
        )
        guard case .unknown = error.kind else {
            Issue.record("Expected .unknown, got \(error.kind)"); return
        }
    }

    @Test func kindIsUnknownForInvalidRequest() {
        let error = EmbeddedAuthError(
            info: ["error": "invalid_request", "error_description": "Bad request."],
            statusCode: 400
        )
        guard case .unknown = error.kind else {
            Issue.record("Expected .unknown, got \(error.kind)"); return
        }
    }
}
