import Testing
import Foundation
@testable import Auth0

/// How `Auth0EmbeddedAuth.updateSessionFromFailure(_:verifier:)` moves `transactionState` and rewrites the error it returns.
struct EmbeddedAuthStateTests {

    // MARK: Fixtures

    private func makeClient() -> Auth0EmbeddedAuth {
        Auth0EmbeddedAuth(clientId: "TEST_CLIENT_ID", url: URL(string: "https://test.auth0.com")!)
    }

    private func signupOffer(requirement: Bool?) -> [String: Any] {
        var entry: [String: Any] = ["action": "action:signup:v1", "identifiers": ["email": ["required": true]]]
        if let requirement { entry["authentication_methods"] = ["password": ["required": requirement]] }
        return entry
    }

    private func confirmEntry() -> [String: Any] {
        ["action": "action:signup:confirm:v1", "password_complexity_options": ["min_length": 8]]
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

    /// A client whose flow was opened, with the PKCE verifier `verifier_1`, by a sign-up offer with the given password
    /// requirement.
    private func client(offering requirement: Bool? = nil) -> Auth0EmbeddedAuth {
        let client = makeClient()
        _ = client.updateSessionFromFailure(continuation(session: "sess_1", next: [signupOffer(requirement: requirement)]),
                                            verifier: "verifier_1")
        return client
    }

    private func passwordFlag(of error: EmbeddedAuthError) -> Bool? {
        guard case .insufficientAuthorization(_, let actions) = error.reason else { return nil }
        for case .confirmSignup(let password) in actions { return password?.isRequired }
        return nil
    }

    // MARK: Continuations

    @Test func aNewClientHasNoFlow() {
        #expect(makeClient().transactionState == nil)
    }

    @Test func aContinuationWithASessionOpensItAndRotatesIt() {
        let client = client()
        #expect(client.transactionState?.authSession == "sess_1")
        _ = client.updateSessionFromFailure(continuation(session: "sess_2"))
        #expect(client.transactionState?.authSession == "sess_2")
    }

    @Test func aContinuationWithoutASessionChangesNothing() {
        let client = client(offering: true)
        let before = client.transactionState
        let error = continuation(session: nil, next: [signupOffer(requirement: false)])
        #expect(client.updateSessionFromFailure(error) == error)
        #expect(client.transactionState == before)
    }

    // MARK: The PKCE verifier

    @Test func aContinuationKeepsTheVerifierOfTheFlow() {
        let client = client()
        _ = client.updateSessionFromFailure(continuation(session: "sess_2"))
        #expect(client.transactionState?.authSession == "sess_2")
        #expect(client.transactionState?.verifier == "verifier_1")
    }

    @Test func anAnswerToAnAuthorizeRequestAdoptsItsOwnVerifier() {
        let client = client()
        _ = client.updateSessionFromFailure(continuation(session: "sess_2"), verifier: "verifier_2")
        #expect(client.transactionState?.authSession == "sess_2")
        #expect(client.transactionState?.verifier == "verifier_2")
    }

    @Test func aLateAnswerWithNoVerifierToAdoptOrCarryOpensNoStateButIsStillDelivered() {
        let client = makeClient()
        let error = continuation(session: "sess_late")
        #expect(client.updateSessionFromFailure(error) == error)
        #expect(client.transactionState == nil)
    }

    @Test func aNetworkFailureOnAnAuthorizeRequestOpensNoState() {
        let client = makeClient()
        let network = EmbeddedAuthError(cause: URLError(.notConnectedToInternet), statusCode: 0)
        #expect(client.updateSessionFromFailure(network, verifier: "verifier_1") == network)
        #expect(client.transactionState == nil)
    }

    @Test func aStateHidesTheSessionAndTheVerifierWhenItIsPrinted() {
        let state = EmbeddedAuthState(authSession: "secret_session", passwordRequirement: .required, verifier: "secret_verifier")
        var dumped = ""
        _ = dump(state, to: &dumped)
        for text in [String(describing: state), String(reflecting: state), "\(state)", dumped] {
            #expect(!text.contains("secret_session"))
            #expect(!text.contains("secret_verifier"))
            #expect(text.contains("<REDACTED>"))
        }
        #expect(String(describing: state).contains("required"))
    }

    @Test func dumpingAClientHidesTheSessionAndTheVerifier() {
        let client = makeClient()
        client.transactionState = EmbeddedAuthState(authSession: "secret_session", verifier: "secret_verifier")
        var dumped = ""
        _ = dump(client, to: &dumped)
        #expect(dumped.contains("transactionState"))
        #expect(!dumped.contains("secret_session"))
        #expect(!dumped.contains("secret_verifier"))
    }

    // MARK: The password requirement

    @Test(arguments: [(true, CredentialRequirement.required), (false, CredentialRequirement.optional)])
    func theSignupOfferSetsTheRequirement(offer: (Bool, CredentialRequirement)) {
        #expect(client(offering: offer.0).transactionState?.passwordRequirement == offer.1)
    }

    @Test func aSignupOfferWithoutPasswordInformationSaysNone() {
        #expect(client(offering: nil).transactionState?.passwordRequirement == CredentialRequirement.none)
    }

    @Test func theFirstSignupOfferWins() {
        let client = makeClient()
        _ = client.updateSessionFromFailure(continuation(next: [signupOffer(requirement: true), signupOffer(requirement: false)]),
                                            verifier: "verifier_1")
        #expect(client.transactionState?.passwordRequirement == .required)
    }

    @Test func aLaterSignupOfferReplacesTheRequirement() {
        let client = client(offering: true)
        _ = client.updateSessionFromFailure(continuation(next: [signupOffer(requirement: false)]))
        #expect(client.transactionState?.passwordRequirement == .optional)
    }

    @Test func aContinuationWithoutASignupOfferKeepsTheRequirement() {
        let client = client(offering: false)
        _ = client.updateSessionFromFailure(continuation(session: "sess_2"))
        #expect(client.transactionState?.passwordRequirement == .optional)
    }

    @Test func aPasswordRequiredAnswerUpgradesTheRequirement() {
        let client = client(offering: false)
        _ = client.updateSessionFromFailure(continuation(description: "password_required"))
        #expect(client.transactionState?.passwordRequirement == .required)
    }

    @Test func aPasswordRequiredAnswerBeatsTheOffer() {
        let client = client(offering: false)
        _ = client.updateSessionFromFailure(continuation(description: "password_required", next: [signupOffer(requirement: false)]))
        #expect(client.transactionState?.passwordRequirement == .required)
    }

    @Test(arguments: ["password_not_accepted", "invalid_password"])
    func theOtherPasswordAnswersDoNotChangeTheRequirement(description: String) {
        let client = client(offering: false)
        _ = client.updateSessionFromFailure(continuation(description: description))
        #expect(client.transactionState?.passwordRequirement == .optional)
    }

    // MARK: The error that is returned

    @Test(arguments: [(true, true), (false, false)])
    func theConfirmActionTakesItsRequiredFlagFromTheOffer(offer: (Bool, Bool)) {
        let client = client(offering: offer.0)
        let delivered = client.updateSessionFromFailure(continuation(next: [confirmEntry()]))
        #expect(passwordFlag(of: delivered) == offer.1)
    }

    @Test func theConfirmActionIsNotRequiredWhenNoOfferWasSeen() {
        let client = makeClient()
        let delivered = client.updateSessionFromFailure(continuation(next: [confirmEntry()]))
        #expect(passwordFlag(of: delivered) == false)
    }

    @Test func aPasswordRequiredAnswerMakesTheReOfferedConfirmRequired() {
        let client = client(offering: false)
        let delivered = client.updateSessionFromFailure(continuation(description: "password_required", next: [confirmEntry()]))
        #expect(passwordFlag(of: delivered) == true)
    }

    @Test func anErrorBuiltOutsideTheClientNeverClaimsThePasswordIsRequired() {
        #expect(passwordFlag(of: continuation(next: [confirmEntry()])) == false)
    }

    @Test func otherActionsAreReturnedUnchanged() {
        let client = client(offering: true)
        let error = continuation(next: [["action": "action:identify:email:v1"], confirmEntry()])
        guard case .insufficientAuthorization(_, let actions) = client.updateSessionFromFailure(error).reason else {
            Issue.record("Expected .insufficientAuthorization"); return
        }
        #expect(actions.first == .identifyEmail)
    }

    @Test func theDeliveredErrorEqualsTheOriginal() {
        let client = client(offering: true)
        let error = continuation(next: [confirmEntry()])
        #expect(client.updateSessionFromFailure(error) == error)
    }

    @Test func anUnchangedErrorIsReturnedAsIs() {
        let client = client(offering: false)
        let error = continuation(next: [["action": "action:identify:email:v1"]])
        #expect(client.updateSessionFromFailure(error).nextActionsOverride == nil)
    }

    // MARK: Other failures

    @Test func aNetworkFailureKeepsEverything() {
        let client = client(offering: true)
        let before = client.transactionState
        let network = EmbeddedAuthError(cause: URLError(.notConnectedToInternet), statusCode: 0)
        #expect(client.updateSessionFromFailure(network) == network)
        #expect(client.transactionState == before)
    }

    @Test(arguments: [
        ["error": "access_denied", "error_description": "too_many_wrong_otp_attempts"],
        ["error": "invalid_request", "error_description": "Invalid request"],
        ["error": "invalid_grant", "error_description": "bad code"],
        ["error": "something_new"]
    ])
    func anyOtherFailureEndsTheFlow(info: [String: String]) {
        let client = client(offering: true)
        let error = EmbeddedAuthError(info: info, statusCode: 403)
        #expect(client.updateSessionFromFailure(error) == error)
        #expect(client.transactionState == nil)
    }
}
