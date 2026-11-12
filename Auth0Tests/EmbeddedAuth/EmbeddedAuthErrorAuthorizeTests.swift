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

    @Test func reasonIsConsentRequiredUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "consent_required"],
            statusCode: 403
        )
        guard case .consentRequired = error.reason else {
            Issue.record("Expected .consentRequired, got \(error.reason)"); return
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

    // MARK: - reason: ip_blocked

    @Test func reasonIsIpBlockedFor429AndIpBlockedDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "ip_blocked"],
            statusCode: 429
        )
        guard case .ipBlocked = error.reason else {
            Issue.record("Expected .ipBlocked, got \(error.reason)"); return
        }
    }

    @Test(arguments: [400, 403])
    func reasonIsIpBlockedForNon429StatusCode(_ statusCode: Int) {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "ip_blocked"],
            statusCode: statusCode
        )
        guard case .ipBlocked = error.reason else {
            Issue.record("Expected .ipBlocked for status \(statusCode), got \(error.reason)"); return
        }
    }

    @Test func reasonIsIpBlockedEvenWhenNextAndAuthSessionArePresent() {
        let error = EmbeddedAuthError(
            info: [
                "error": "too_many_requests",
                "error_description": "ip_blocked",
                "auth_session": "sess_x",
                "next": [["action": "action:verify:recovery-code:v1"]]
            ],
            statusCode: 429
        )
        guard case .ipBlocked = error.reason else {
            Issue.record("Expected .ipBlocked, got \(error.reason)"); return
        }
    }

    @Test func reasonIsUnknownForTooManyRequestsWithUnrecognisedDescription() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "Rate limit exceeded"],
            statusCode: 429
        )
        guard case .unknown = error.reason else {
            Issue.record("Expected .unknown, got \(error.reason)"); return
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

    // MARK: - reason: MFA terminal errors

    @Test func reasonIsAuthorizationRejectedUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "authorization_rejected"],
            statusCode: 403
        )
        guard case .authorizationRejected = error.reason else {
            Issue.record("Expected .authorizationRejected, got \(error.reason)"); return
        }
    }

    @Test func reasonIsNoNextStepsUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "no_next_steps"],
            statusCode: 403
        )
        guard case .noNextSteps = error.reason else {
            Issue.record("Expected .noNextSteps, got \(error.reason)"); return
        }
    }

    @Test func reasonIsPasswordLeakedUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "password_leaked"],
            statusCode: 403
        )
        guard case .passwordLeaked = error.reason else {
            Issue.record("Expected .passwordLeaked, got \(error.reason)"); return
        }
    }

    // The descriptions that point to `custom_error_message` / `custom_error_code` are not modelled yet.
    @Test(arguments: ["denied", "validation_error"])
    func reasonIsAccessDeniedForDescriptionsThatCarryCustomErrorFields(description: String) {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied",
                   "error_description": description,
                   "custom_error_message": "Blocked by policy.",
                   "custom_error_code": "policy_blocked"],
            statusCode: 403
        )
        guard case .accessDenied = error.reason else {
            Issue.record("Expected .accessDenied, got \(error.reason)"); return
        }
        #expect(error.info["custom_error_message"] as? String == "Blocked by policy.")
        #expect(error.info["custom_error_code"] as? String == "policy_blocked")
    }

    @Test func reasonIsNoEligibleFactorsUnderAccessDenied() {
        let error = EmbeddedAuthError(
            info: ["error": "access_denied", "error_description": "no_eligible_factors"],
            statusCode: 403
        )
        guard case .noEligibleFactors = error.reason else {
            Issue.record("Expected .noEligibleFactors, got \(error.reason)"); return
        }
    }

    // MARK: - next parsing: MFA actions

    @Test func reasonParsesIdentifyPhone() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:identify:phone:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.identifyPhone])
    }

    @Test func reasonParsesIdentifyUsername() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:identify:username:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.identifyUsername])
    }

    @Test func reasonParsesChallengePhoneWithDeliveryMethods() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****567", "delivery_methods": ["text", "voice"]]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .challengePhone(let index, let identifier, let methods) = actions.first else {
            Issue.record("Expected .challengePhone"); return
        }
        #expect(index == 0)
        #expect(identifier == "+1*****567")
        #expect(methods == [.text, .voice])
    }

    @Test func reasonParsesChallengePhoneWithEmptyDeliveryMethods() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****567", "delivery_methods": []]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .challengePhone(_, _, let methods) = actions.first else {
            Issue.record("Expected .challengePhone"); return
        }
        #expect(methods.isEmpty)
    }

    @Test func reasonDropsChallengePhoneMissingIndex() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "identifier": "+1*****567", "delivery_methods": ["text"]]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonDropsChallengePhoneMissingIdentifier() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "index": 0, "delivery_methods": ["text"]]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonDropsChallengePhoneMissingDeliveryMethods() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****567"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonDropsChallengePhoneWithMalformedDeliveryMethods() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****567", "delivery_methods": "text"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonKeepsOtherActionsWhenChallengePhoneIsDropped() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [
                ["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****567"],
                ["action": "action:verify:recovery-code:v1"]
            ]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.verifyRecoveryCode])
    }

    @Test func reasonIgnoresUnknownDeliveryMethodsButKeepsKnownOnes() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "index": 1, "identifier": "+1*****567",
                      "delivery_methods": ["text", "whatsapp"]]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.challengePhone(index: 1, identifier: "+1*****567", deliveryMethods: [.text])])
    }

    @Test func reasonKeepsChallengePhoneWhenOnlyUnknownDeliveryMethodsAreOffered() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****567",
                      "delivery_methods": ["whatsapp"]]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.challengePhone(index: 0, identifier: "+1*****567", deliveryMethods: [])])
    }

    @Test func reasonParsesChallengePush() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:push:v1", "index": 0, "name": "Diego's iPhone"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .challengePush(let index, let name) = actions.first else {
            Issue.record("Expected .challengePush"); return
        }
        #expect(index == 0)
        #expect(name == "Diego's iPhone")
    }

    @Test func reasonDropsChallengePushMissingIndex() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:push:v1", "name": "Diego's iPhone"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonDropsChallengePushMissingName() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:challenge:push:v1", "index": 0]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonParsesVerifyOobWithPollInMs() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:verify:oob:v1", "poll_in_ms": 2000]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .verifyOob(let pollInMs) = actions.first else {
            Issue.record("Expected .verifyOob"); return
        }
        #expect(pollInMs == 2000)
    }

    @Test func reasonDropsVerifyOobMissingPollInMs() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:verify:oob:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonParsesVerifyRecoveryCode() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:verify:recovery-code:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.verifyRecoveryCode])
    }

    @Test func reasonParsesConfirmRecoveryCodeWithNewCode() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:confirm:recovery-code:v1", "new_code": "EFGH-5678"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason,
              case .confirmRecoveryCode(let newCode) = actions.first else {
            Issue.record("Expected .confirmRecoveryCode"); return
        }
        #expect(newCode == "EFGH-5678")
    }

    @Test func reasonDropsConfirmRecoveryCodeMissingNewCode() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:confirm:recovery-code:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.isEmpty)
    }

    @Test func reasonDecodesMixedEmailAndMfaActions() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [
                ["action": "action:verify:otp:v1", "channel": "totp"],
                ["action": "action:challenge:push:v1", "index": 0, "name": "My Phone"],
                ["action": "action:challenge:phone:v1", "index": 0, "identifier": "+1*****89", "delivery_methods": ["text", "voice"]]
            ]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.count == 3)
        guard case .verifyOTP(let ch, _) = actions[0] else {
            Issue.record("Expected .verifyOTP at index 0"); return
        }
        #expect(ch == .totp)
        guard case .challengePush(let idx, let name) = actions[1] else {
            Issue.record("Expected .challengePush at index 1"); return
        }
        #expect(idx == 0)
        #expect(name == "My Phone")
        guard case .challengePhone(let phoneIdx, _, let methods) = actions[2] else {
            Issue.record("Expected .challengePhone at index 2"); return
        }
        #expect(phoneIdx == 0)
        #expect(methods.contains(.text))
        #expect(methods.contains(.voice))
    }

    // MARK: - verify password

    @Test func reasonIsInvalidIdentifierOrPasswordUnderInsufficientAuthorization() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization", "error_description": "invalid_identifier_or_password"],
            statusCode: 403
        )
        guard case .insufficientAuthorization(.invalidIdentifierOrPassword, _) = error.reason else {
            Issue.record("Expected .invalidIdentifierOrPassword, got \(error.reason)"); return
        }
    }

    @Test func invalidIdentifierOrPasswordCarriesNextActions() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "error_description": "invalid_identifier_or_password",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:password:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(.invalidIdentifierOrPassword, let actions) = error.reason else {
            Issue.record("Expected .invalidIdentifierOrPassword, got \(error.reason)"); return
        }
        #expect(actions == [.verifyPassword])
    }

    @Test func reasonParsesVerifyPassword() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:verify:password:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.verifyPassword])
    }

    @Test func reasonDecodesVerifyPasswordAlongsideOtherActions() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [
                ["action": "action:verify:password:v1"],
                ["action": "action:challenge:email:v1", "index": 0, "identifier": "al**@example.com"]
            ]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.verifyPassword, .challengeEmail(index: 0, identifier: "al**@example.com")])
    }

    // MARK: - sign up

    private func signupActions(_ entries: [[String: Any]]) -> [NextAction]? {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": entries
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else { return nil }
        return actions
    }

    @Test func reasonParsesSignupWithRequiredEmail() {
        let actions = signupActions([["action": "action:signup:v1", "identifiers": ["email": ["required": true]]]])
        #expect(actions == [.signup(identifiers: [SignupIdentifier(type: .email, isRequired: true)], passwordRequirement: .none)])
    }

    @Test func reasonParsesSignupWithOptionalPhone() {
        let actions = signupActions([["action": "action:signup:v1", "identifiers": ["phone_number": ["required": false]]]])
        #expect(actions == [.signup(identifiers: [SignupIdentifier(type: .phone, isRequired: false)], passwordRequirement: .none)])
    }

    @Test func reasonParsesSignupWithBothIdentifiersInAFixedOrder() {
        let identifiers: [String: Any] = ["phone_number": ["required": false], "email": ["required": true]]
        // Dictionaries have no order, so repeat to make sure the result never depends on it.
        for _ in 0..<20 {
            let actions = signupActions([["action": "action:signup:v1", "identifiers": identifiers]])
            #expect(actions == [.signup(identifiers: [SignupIdentifier(type: .email, isRequired: true),
                                                      SignupIdentifier(type: .phone, isRequired: false)], passwordRequirement: .none)])
        }
    }

    @Test func reasonDropsSignupMissingIdentifiers() {
        let actions = signupActions([["action": "action:signup:v1"], ["action": "action:identify:email:v1"]])
        #expect(actions == [.identifyEmail])
    }

    @Test func reasonDropsSignupWhoseIdentifiersAreNotAnObject() {
        #expect(signupActions([["action": "action:signup:v1", "identifiers": ["email", "phone_number"]]]) == [])
        #expect(signupActions([["action": "action:signup:v1", "identifiers": "email"]]) == [])
    }

    @Test func reasonKeepsSignupWithOnlyUnknownIdentifierKeys() {
        let actions = signupActions([["action": "action:signup:v1", "identifiers": ["username": ["required": true]]]])
        #expect(actions == [.signup(identifiers: [], passwordRequirement: .none)])
    }

    @Test func reasonIgnoresUnknownSignupIdentifierKeysNextToKnownOnes() {
        let actions = signupActions([[
            "action": "action:signup:v1",
            "identifiers": ["username": ["required": true], "email": ["required": true]]
        ]])
        #expect(actions == [.signup(identifiers: [SignupIdentifier(type: .email, isRequired: true)], passwordRequirement: .none)])
    }

    @Test func reasonSkipsSignupIdentifierWhoseRequiredFlagIsMissingOrNotABoolean() {
        let missing = signupActions([[
            "action": "action:signup:v1",
            "identifiers": ["email": [String: Any](), "phone_number": ["required": true]]
        ]])
        #expect(missing == [.signup(identifiers: [SignupIdentifier(type: .phone, isRequired: true)], passwordRequirement: .none)])

        let notABool = signupActions([[
            "action": "action:signup:v1",
            "identifiers": ["email": ["required": "true"], "phone_number": ["required": true]]
        ]])
        #expect(notABool == [.signup(identifiers: [SignupIdentifier(type: .phone, isRequired: true)], passwordRequirement: .none)])

        let notAnObject = signupActions([["action": "action:signup:v1", "identifiers": ["email": true]]])
        #expect(notAnObject == [.signup(identifiers: [], passwordRequirement: .none)])
    }

    @Test func reasonParsesConfirmSignup() {
        #expect(signupActions([["action": "action:signup:confirm:v1"]]) == [.confirmSignup(password: nil)])
    }

    @Test func reasonTreatsAnotherSignupVersionAsUnknown() {
        let actions = signupActions([["action": "action:signup:v2"], ["action": "action:signup:confirm:v2"]])
        #expect(actions == [.unknown(rawAction: "action:signup:v2"), .unknown(rawAction: "action:signup:confirm:v2")])
    }

    // MARK: - password sign-up: sub-reasons

    private func subReasonName(_ description: String?, status: Int = 403, code: String = "insufficient_authorization") -> String? {
        var info: [String: Any] = ["error": code, "auth_session": "sess_abc", "next": [["action": "action:signup:confirm:v1"]]]
        if let description { info["error_description"] = description }
        let reason = EmbeddedAuthError(info: info, statusCode: status).reason
        guard case .insufficientAuthorization(let sub, let actions) = reason else { return nil }
        #expect(actions == [.confirmSignup(password: nil)])
        return String(describing: sub)
    }

    @Test func reasonMapsThePasswordSignupSubReasonsAndParsesNextActions() {
        #expect(subReasonName("password_required") == "passwordRequired")
        #expect(subReasonName("password_not_accepted") == "passwordNotAccepted")
        #expect(subReasonName("invalid_password") == "invalidPassword")
    }

    @Test func reasonKeepsUnrecognisedInsufficientAuthorizationDescriptionsAsNone() {
        #expect(subReasonName("unknown_error") == "none")
        #expect(subReasonName("password_required_please") == "none")
        #expect(subReasonName("Password_Required") == "none")
        #expect(subReasonName(nil) == "none")
    }

    @Test func reasonDoesNotMapThePasswordSubReasonsUnderOtherErrorCodes() {
        let denied = EmbeddedAuthError(info: ["error": "access_denied", "error_description": "password_required"], statusCode: 403)
        guard case .accessDenied = denied.reason else {
            Issue.record("Expected .accessDenied, got \(denied.reason)"); return
        }
    }

    @Test func reasonMapsPasswordLeakedToItsOwnTerminalReason() {
        let error = EmbeddedAuthError(info: ["error": "access_denied", "error_description": "password_leaked"], statusCode: 403)
        guard case .passwordLeaked = error.reason else {
            Issue.record("Expected .passwordLeaked, got \(error.reason)"); return
        }
    }

    // MARK: - password sign-up: sign-up offer

    private func signupOffer(_ methods: Any?) -> [NextAction]? {
        var entry: [String: Any] = ["action": "action:signup:v1", "identifiers": ["email": ["required": true]]]
        if let methods { entry["authentication_methods"] = methods }
        return signupActions([entry])
    }

    private let requiredEmail = SignupIdentifier(type: .email, isRequired: true)

    @Test func reasonReadsTheSignupPasswordRequirement() {
        #expect(signupOffer(nil) == [.signup(identifiers: [requiredEmail], passwordRequirement: .none)])
        #expect(signupOffer(["password": ["required": true]]) == [.signup(identifiers: [requiredEmail], passwordRequirement: .required)])
        #expect(signupOffer(["password": ["required": false]]) == [.signup(identifiers: [requiredEmail], passwordRequirement: .optional)])
    }

    @Test func reasonTreatsAnUnreadablePasswordRequirementAsNoneAndKeepsTheIdentifiers() {
        let none = [NextAction.signup(identifiers: [requiredEmail], passwordRequirement: .none)]
        // A sibling method this SDK does not know, without a password key.
        #expect(signupOffer(["passkey": ["required": true]]) == none)
        #expect(signupOffer(["password": ["required": "true"]]) == none)
        #expect(signupOffer(["password": [String: Any]()]) == none)
        #expect(signupOffer(["password": true]) == none)
        #expect(signupOffer("password") == none)
        #expect(signupOffer(["password"]) == none)
        #expect(signupOffer([String: Any]()) == none)
    }

    @Test func reasonReadsThePasswordRequirementNextToAnUnknownSibling() {
        let offer = signupOffer(["passkey": ["required": true], "password": ["required": false]])
        #expect(offer == [.signup(identifiers: [requiredEmail], passwordRequirement: .optional)])
    }

    // MARK: - password sign-up: confirm entry

    private func confirmEntry(_ options: Any?) -> [String: Any] {
        var entry: [String: Any] = ["action": "action:signup:confirm:v1"]
        if let options { entry["password_complexity_options"] = options }
        return entry
    }

    private func confirmActions(_ options: Any?, requirement: CredentialRequirement? = nil) -> [NextAction]? {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [confirmEntry(options)]
        ], statusCode: 403).withSignupPasswordRequirement(requirement)
        guard case .insufficientAuthorization(_, let actions) = error.reason else { return nil }
        return actions
    }

    @Test func reasonParsesConfirmSignupWithoutPasswordOptions() {
        #expect(confirmActions(nil) == [.confirmSignup(password: nil)])
    }

    @Test func reasonParsesConfirmSignupWithFullPasswordOptions() {
        let options: [String: Any] = ["min_length": 12, "character_types": ["lowercase", "uppercase", "number", "special"]]
        let complexity = SignupPasswordComplexity(minLength: 12, characterTypes: [.lowercase, .uppercase, .number, .special])
        #expect(confirmActions(options) == [.confirmSignup(password: SignupPassword(isRequired: true, complexity: complexity))])
    }

    @Test func reasonParsesPasswordOptionsWithoutCharacterTypes() {
        let complexity = SignupPasswordComplexity(minLength: 8, characterTypes: [])
        #expect(confirmActions(["min_length": 8]) == [.confirmSignup(password: SignupPassword(isRequired: true, complexity: complexity))])
    }

    @Test func reasonLeavesOutUnknownCharacterTypes() {
        let complexity = SignupPasswordComplexity(minLength: 8, characterTypes: [.number, .special])
        let options: [String: Any] = ["min_length": 8, "character_types": ["number", "emoji", 5, "special", "Number"]]
        #expect(confirmActions(options) == [.confirmSignup(password: SignupPassword(isRequired: true, complexity: complexity))])
    }

    @Test func reasonRemovesDuplicateCharacterTypesKeepingTheOrder() {
        let complexity = SignupPasswordComplexity(minLength: 8, characterTypes: [.special, .number, .lowercase])
        let options: [String: Any] = ["min_length": 8, "character_types": ["special", "number", "special", "lowercase", "number"]]
        #expect(confirmActions(options) == [.confirmSignup(password: SignupPassword(isRequired: true, complexity: complexity))])
    }

    @Test func reasonTreatsCharacterTypesThatAreNotAnArrayAsEmpty() {
        let complexity = SignupPasswordComplexity(minLength: 8, characterTypes: [])
        let expected = [NextAction.confirmSignup(password: SignupPassword(isRequired: true, complexity: complexity))]
        #expect(confirmActions(["min_length": 8, "character_types": "number"]) == expected)
        #expect(confirmActions(["min_length": 8, "character_types": ["number": true]]) == expected)
    }

    @Test func reasonDropsConfirmSignupWhoseMinLengthCannotBeRead() {
        #expect(confirmActions([String: Any]()) == [])
        #expect(confirmActions(["character_types": ["number"]]) == [])
        #expect(confirmActions(["min_length": "8"]) == [])
        #expect(confirmActions(["min_length": 8.5]) == [])
    }

    @Test func reasonDropsConfirmSignupWhoseOptionsAreNotAnObject() {
        #expect(confirmActions("min_length") == [])
        #expect(confirmActions([8]) == [])
        #expect(confirmActions(true) == [])
    }

    @Test func reasonKeepsSiblingsOfADroppedConfirmSignup() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:identify:email:v1"], confirmEntry("bad"), ["action": "action:verify:password:v1"]]
        ], statusCode: 403)
        guard case .insufficientAuthorization(_, let actions) = error.reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions == [.identifyEmail, .verifyPassword])
    }

    @Test func reasonDoesNotRangeCheckMinLength() {
        let complexity = SignupPasswordComplexity(minLength: 0, characterTypes: [])
        #expect(confirmActions(["min_length": 0]) == [.confirmSignup(password: SignupPassword(isRequired: true, complexity: complexity))])
    }

    @Test func reasonDerivesIsRequiredFromTheFlowRequirement() {
        let options: [String: Any] = ["min_length": 8]
        func isRequired(_ requirement: CredentialRequirement?) -> Bool? {
            guard case .confirmSignup(let password)? = confirmActions(options, requirement: requirement)?.first else { return nil }
            return password?.isRequired
        }
        #expect(isRequired(.optional) == false)
        #expect(isRequired(.required) == true)
        #expect(isRequired(CredentialRequirement.none) == true)
        #expect(isRequired(nil) == true)
    }

    @Test func theFlowRequirementDoesNotChangeErrorEquality() {
        let error = EmbeddedAuthError(info: ["error": "insufficient_authorization"], statusCode: 403)
        #expect(error.withSignupPasswordRequirement(.optional) == error)
    }

    @Test func reasonKeepsOtherSignupVersionsUnknownNextToPasswordOptions() {
        let actions = signupActions([["action": "action:signup:v2", "authentication_methods": ["password": ["required": true]]],
                                     ["action": "action:signup:confirm:v2", "password_complexity_options": ["min_length": 8]]])
        #expect(actions == [.unknown(rawAction: "action:signup:v2"), .unknown(rawAction: "action:signup:confirm:v2")])
    }

    @Test func passwordSignupTypesHaveTheDocumentedShape() {
        #expect(SignupPasswordComplexity.CharacterType.allCases.map(\.rawValue) == ["lowercase", "uppercase", "number", "special"])
    }
}
