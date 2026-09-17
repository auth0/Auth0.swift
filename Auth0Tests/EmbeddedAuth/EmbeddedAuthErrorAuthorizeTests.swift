import Testing
import Foundation
@testable import Auth0

@Suite struct EmbeddedAuthErrorAuthorizeTests {

    // MARK: isInsufficientAuthorization

    @Test func insufficientAuthorizationIsTrueForCorrectCode() {
        let error = EmbeddedAuthError(
            info: ["error": "insufficient_authorization"],
            statusCode: 403
        )
        #expect(error.isInsufficientAuthorization)
    }

    @Test func insufficientAuthorizationIsFalseForOtherCodes() {
        let error = EmbeddedAuthError(info: ["error": "access_denied"], statusCode: 403)
        #expect(!error.isInsufficientAuthorization)
    }

    // MARK: isAccessDenied

    @Test func accessDeniedIsTrueForCorrectCode() {
        let error = EmbeddedAuthError(info: ["error": "access_denied"], statusCode: 403)
        #expect(error.isAccessDenied)
    }

    @Test func accessDeniedIsFalseForOtherCodes() {
        let error = EmbeddedAuthError(info: ["error": "insufficient_authorization"], statusCode: 403)
        #expect(!error.isAccessDenied)
    }

    // MARK: isTooManyAttempts

    @Test func tooManyAttemptsTrueWhenBothFieldsMatch() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 429
        )
        #expect(error.isTooManyAttempts)
    }

    @Test func tooManyAttemptsFalseWhenDescriptionDiffers() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_logins"],
            statusCode: 429
        )
        #expect(!error.isTooManyAttempts)
    }

    // MARK: isTooManyLogins

    @Test func tooManyLoginsTrueWhenBothFieldsMatch() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_logins"],
            statusCode: 429
        )
        #expect(error.isTooManyLogins)
    }

    @Test func tooManyLoginsFalseWhenDescriptionDiffers() {
        let error = EmbeddedAuthError(
            info: ["error": "too_many_requests", "error_description": "too_many_attempts"],
            statusCode: 429
        )
        #expect(!error.isTooManyLogins)
    }

    // MARK: nextActions — identifyEmail

    @Test func nextActionsDecodesIdentifyEmail() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:identify:email:v1"]]
        ], statusCode: 403)
        #expect(error.nextActions == [.identifyEmail])
    }

    // MARK: nextActions — identifyPhone

    @Test func nextActionsDecodesIdentifyPhone() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:identify:phone:v1"]]
        ], statusCode: 403)
        #expect(error.nextActions == [.identifyPhone])
    }

    // MARK: nextActions — challengeEmail

    @Test func nextActionsDecodesChallengeEmail() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:challenge:email:v1"]]
        ], statusCode: 403)
        #expect(error.nextActions == [.challengeEmail])
    }

    // MARK: nextActions — verifyOTP with channel and identifier

    @Test func nextActionsDecodesVerifyOTPWithChannelAndIdentifier() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]
        ], statusCode: 403)
        guard case .verifyOTP(let channel, let identifier) = error.nextActions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == "email")
        #expect(identifier == "al**@example.com")
    }

    @Test func nextActionsDecodesVerifyOTPWithNilFields() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "auth_session": "sess_abc",
            "next": [["action": "action:verify:otp:v1"]]
        ], statusCode: 403)
        guard case .verifyOTP(let channel, let identifier) = error.nextActions.first else {
            Issue.record("Expected .verifyOTP"); return
        }
        #expect(channel == nil)
        #expect(identifier == nil)
    }

    // MARK: nextActions — unknown action

    @Test func nextActionsDecodesUnknownAction() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [["action": "action:future:v99"]]
        ], statusCode: 403)
        guard case .unknown(let raw) = error.nextActions.first else {
            Issue.record("Expected .unknown"); return
        }
        #expect(raw == "action:future:v99")
    }

    @Test func nextActionsIsEmptyWhenNextKeyAbsent() {
        let error = EmbeddedAuthError(info: ["error": "access_denied"], statusCode: 403)
        #expect(error.nextActions.isEmpty)
    }

    @Test func nextActionsDecodesMultipleActions() {
        let error = EmbeddedAuthError(info: [
            "error": "insufficient_authorization",
            "next": [
                ["action": "action:identify:email:v1"],
                ["action": "action:identify:phone:v1"]
            ]
        ], statusCode: 403)
        #expect(error.nextActions.count == 2)
        #expect(error.nextActions[0] == .identifyEmail)
        #expect(error.nextActions[1] == .identifyPhone)
    }

}
