import Testing
import Foundation
@testable import Auth0

/// The transitions of `EmbeddedAuthFlowState`, one per row of the table in its documentation.
struct EmbeddedAuthFlowStateTests {

    // MARK: Fixtures

    private func signupOffer(requirement: Bool?) -> [String: Any] {
        var entry: [String: Any] = ["action": "action:signup:v1", "identifiers": ["email": ["required": true]]]
        if let requirement { entry["authentication_methods"] = ["password": ["required": requirement]] }
        return entry
    }

    /// A `403 insufficient_authorization` answer.
    private func continuation(session: String? = "sess_next",
                              description: String? = nil,
                              next: [[String: Any]] = [["action": "action:identify:email:v1"]]) -> EmbeddedAuthError {
        var info: [String: Any] = ["error": "insufficient_authorization", "next": next]
        if let session { info["auth_session"] = session }
        if let description { info["error_description"] = description }
        return EmbeddedAuthError(info: info, statusCode: 403)
    }

    private func started(requirement: Bool? = nil) -> EmbeddedAuthFlowState {
        var state = EmbeddedAuthFlowState()
        state.apply(continuation(session: "sess_1", next: [signupOffer(requirement: requirement)]))
        return state
    }

    // MARK: Transitions

    @Test func aNewStateHasNoFlow() {
        let state = EmbeddedAuthFlowState()
        #expect(state.session == nil)
        #expect(state.signupPasswordRequirement == nil)
    }

    @Test func aContinuationWithASessionOpensItAndRotatesIt() {
        var state = started()
        #expect(state.session == "sess_1")
        state.apply(continuation(session: "sess_2"))
        #expect(state.session == "sess_2")
    }

    @Test func aContinuationWithoutASessionKeepsTheCurrentOne() {
        var state = started()
        state.apply(continuation(session: nil))
        #expect(state.session == "sess_1")
    }

    @Test(arguments: [(true, CredentialRequirement.required), (false, CredentialRequirement.optional)])
    func theSignupOfferSetsTheRequirement(offer: (Bool, CredentialRequirement)) {
        #expect(started(requirement: offer.0).signupPasswordRequirement == offer.1)
    }

    @Test func aSignupOfferWithoutPasswordInformationSaysNone() {
        #expect(started(requirement: nil).signupPasswordRequirement == CredentialRequirement.none)
    }

    @Test func theLastSignupOfferWins() {
        var state = started(requirement: true)
        state.apply(continuation(next: [signupOffer(requirement: false)]))
        #expect(state.signupPasswordRequirement == .optional)
    }

    @Test func aContinuationWithoutASignupOfferKeepsTheRequirement() {
        var state = started(requirement: false)
        state.apply(continuation(session: "sess_2"))
        #expect(state.signupPasswordRequirement == .optional)
    }

    @Test func aPasswordRequiredAnswerUpgradesTheRequirement() {
        var state = started(requirement: false)
        state.apply(continuation(description: "password_required"))
        #expect(state.signupPasswordRequirement == .required)
    }

    @Test func aPasswordRequiredAnswerBeatsTheOffer() {
        var state = started(requirement: false)
        state.apply(continuation(description: "password_required", next: [signupOffer(requirement: false)]))
        #expect(state.signupPasswordRequirement == .required)
    }

    @Test func theOtherPasswordAnswersDoNotChangeTheRequirement() {
        for description in ["password_not_accepted", "invalid_password"] {
            var state = started(requirement: false)
            state.apply(continuation(description: description))
            #expect(state.signupPasswordRequirement == .optional, "\(description)")
        }
    }

    @Test func aNetworkFailureKeepsEverything() {
        var state = started(requirement: true)
        let network = EmbeddedAuthError(cause: URLError(.notConnectedToInternet), statusCode: 0)
        state.apply(network)
        #expect(state.session == "sess_1")
        #expect(state.signupPasswordRequirement == .required)
    }

    @Test(arguments: [
        ["error": "access_denied", "error_description": "too_many_wrong_otp_attempts"],
        ["error": "invalid_request", "error_description": "Invalid request"],
        ["error": "invalid_grant", "error_description": "bad code"],
        ["error": "something_new"]
    ])
    func anyOtherFailureEndsTheFlow(info: [String: String]) {
        var state = started(requirement: true)
        state.apply(EmbeddedAuthError(info: info, statusCode: 403))
        #expect(state == EmbeddedAuthFlowState())
    }

    @Test func endForgetsEverything() {
        var state = started(requirement: true)
        state.end()
        #expect(state == EmbeddedAuthFlowState())
    }
}
