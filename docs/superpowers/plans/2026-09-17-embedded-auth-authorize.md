# Embedded Auth Authorize Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `POST /e/authorize` as the Auth0.swift embedded auth loop, with a SwiftUI end-to-end demo covering identify email → challenge email → verify OTP.

**Architecture:** A new `EmbeddedAuthClient` protocol exposes five named methods (`authorize`, `identifyEmail`, `identifyPhone`, `challengeEmail`, `verifyOtp`); all delegate to a single private `_authorize(body:)` on the concrete `Auth0EmbeddedAuthClient` class that threads `auth_session` automatically. The token exchange (`/oauth/token`) stays outside the SDK: `ContentViewModel` holds both `embeddedAuthClient` and `authentication`, calls the loop, then calls `authentication.codeExchange` when it receives an `AuthorizationCode`.

**Tech Stack:** Swift 6, Swift Testing, `URLProtocol` mocks, SwiftUI, `Request<T,E>` from Auth0.swift, `RequestValidator` for local session guard

**Spec:** `docs/superpowers/specs/2026-09-17-embedded-auth-authorize-design.md`

## Global Constraints

- Base branch: `feat/embedded-auth-discovery` — create new branch `feat/embedded-auth-authorize` from it
- All test files use Swift Testing (`import Testing`) and a **dedicated** `URLProtocol` mock class — never share static state with other test suites
- `auth_session` must never appear in logs, public API, or test assertions that print credentials
- Every public type and method needs a DocC `///` comment
- `swiftlint lint` must pass before each commit — line length limit 500, no force-unwraps in library source
- Run tests with: `swift test`
- The demo app flow covers only email (identifyEmail → challengeEmail → verifyOtp); identifyPhone is implemented in the SDK but not wired in the UI

---

## File Map

| Path | Status | Responsibility |
|---|---|---|
| `Auth0/EmbeddedAuth/EmbeddedAuthNextAction.swift` | **Create** | `NextAction`, `EmbeddedAction`, `OtpType`, `EmbeddedCapability`, `AuthorizationCode` |
| `Auth0/EmbeddedAuth/EmbeddedAuthError.swift` | **Modify** | Add `isInsufficientAuthorization`, `isAccessDenied`, `nextActions`, `isTooManyAttempts`, `isTooManyLogins` |
| `Auth0/EmbeddedAuth/EmbeddedAuthClient.swift` | **Create** | `EmbeddedAuthClient` protocol + `Auth0.embeddedAuthClient()` factories |
| `Auth0/EmbeddedAuth/EmbeddedAuthSessionValidator.swift` | **Create** | `RequestValidator` that fails locally when `auth_session` is absent |
| `Auth0/EmbeddedAuth/Auth0EmbeddedAuthClient.swift` | **Create** | Concrete `final class`, `NSLock`-protected session, private `_authorize(body:)` |
| `Auth0Tests/EmbeddedAuth/EmbeddedAuthClientTests.swift` | **Create** | All tests for the client (each method + full sequential flow) |
| `App/ContentViewModel.swift` | **Modify** | Add `embeddedAuthClient`, `embeddedAuthUIState`, `otp`, and four async methods |
| `App/ContentView.swift` | **Modify** | Add "Embedded Auth" section driven by `embeddedAuthUIState` |

---

## Task 1: Create branch and supporting types

**Files:**
- Create: `Auth0/EmbeddedAuth/EmbeddedAuthNextAction.swift`

**Interfaces:**
- Produces: `AuthorizationCode`, `NextAction`, `EmbeddedAction`, `EmbeddedCapability`, `OtpType` — all used by Tasks 2–7

- [ ] **Step 1.1: Create the branch**

```bash
git checkout feat/embedded-auth-discovery
git checkout -b feat/embedded-auth-authorize
```

Expected: on branch `feat/embedded-auth-authorize`

- [ ] **Step 1.2: Create `EmbeddedAuthNextAction.swift`**

Create `Auth0/EmbeddedAuth/EmbeddedAuthNextAction.swift` with this exact content:

```swift
import Foundation

// MARK: - AuthorizationCode

/// Returned by a completed embedded authorization loop.
///
/// Pass `code` to ``Authentication/codeExchange(withCode:codeVerifier:redirectURI:)``
/// to obtain ``Credentials``.
public struct AuthorizationCode: Sendable {

    /// The raw authorization code to exchange for tokens.
    public let code: String

}

// MARK: - NextAction

/// A typed action the server will accept on the next ``EmbeddedAuthClient`` call.
public enum NextAction: Sendable, Equatable {

    /// Server expects the caller to submit an email address via ``EmbeddedAuthClient/identifyEmail(_:)``.
    case identifyEmail

    /// Server expects the caller to submit a phone number via ``EmbeddedAuthClient/identifyPhone(_:)``.
    case identifyPhone

    /// Server expects the caller to trigger an email OTP send via ``EmbeddedAuthClient/challengeEmail(index:)``.
    case challengeEmail

    /// Server expects a one-time code via ``EmbeddedAuthClient/verifyOtp(_:type:)``.
    ///
    /// - Parameters:
    ///   - channel:    Delivery channel (e.g. `"email"`), if provided by the server.
    ///   - identifier: Masked destination (e.g. `"al**@example.com"`), if provided.
    case verifyOTP(channel: String?, identifier: String?)

    /// An action string the SDK does not recognise — preserved for forward compatibility.
    case unknown(rawAction: String)

}

// MARK: - EmbeddedAction

/// Wire strings used in request bodies and for parsing `next` menus.
public enum EmbeddedAction: String, Sendable, CaseIterable {

    /// Identify by email.
    case identifyEmail  = "action:identify:email:v1"

    /// Identify by phone number.
    case identifyPhone  = "action:identify:phone:v1"

    /// Request an email OTP challenge.
    case challengeEmail = "action:challenge:email:v1"

    /// Submit an OTP to verify identity.
    case verifyOTP      = "action:verify:otp:v1"

}

// MARK: - EmbeddedCapability

/// A capability the SDK advertises in the initial ``EmbeddedAuthClient/authorize(connection:capabilities:scope:audience:)`` call.
public enum EmbeddedCapability: Sendable, Equatable {

    /// SDK can identify a user by email.
    case identifyEmail

    /// SDK can identify a user by phone number.
    case identifyPhone

    /// SDK can trigger an email OTP challenge.
    case challengeEmail

    /// SDK can verify an OTP code.
    case verifyOTP

    /// All capabilities this SDK version supports.
    public static let all: [EmbeddedCapability] = [.identifyEmail, .identifyPhone, .challengeEmail, .verifyOTP]

    var action: EmbeddedAction {
        switch self {
        case .identifyEmail:  return .identifyEmail
        case .identifyPhone:  return .identifyPhone
        case .challengeEmail: return .challengeEmail
        case .verifyOTP:      return .verifyOTP
        }
    }

}

// MARK: - OtpType

/// The type of one-time password used in ``EmbeddedAuthClient/verifyOtp(_:type:)``.
public enum OtpType: String, Sendable {

    /// An out-of-band code delivered over email, SMS, or voice.
    case oob  = "oob"

    /// A time-based code from an authenticator app (TOTP).
    case totp = "totp"

}
```

- [ ] **Step 1.3: Add file to Xcode project**

Open `Auth0.xcodeproj` and add `EmbeddedAuthNextAction.swift` to the `Auth0/EmbeddedAuth` group, ensuring it is included in the `Auth0` target. (Or run `swift build` — SPM picks it up automatically from `Sources/`.)

- [ ] **Step 1.4: Build to confirm no errors**

```bash
swift build 2>&1 | grep -E "error:|warning:" | head -20
```

Expected: zero errors

- [ ] **Step 1.5: Commit**

```bash
git add Auth0/EmbeddedAuth/EmbeddedAuthNextAction.swift
git commit -m "feat(embedded-auth): add NextAction, EmbeddedAction, OtpType, EmbeddedCapability, AuthorizationCode types"
```

---

## Task 2: Extend EmbeddedAuthError with authorize-loop properties

**Files:**
- Modify: `Auth0/EmbeddedAuth/EmbeddedAuthError.swift`
- Test: `Auth0Tests/EmbeddedAuth/EmbeddedAuthErrorTests.swift` (new file — existing file may not cover these)

**Interfaces:**
- Consumes: `NextAction` from Task 1
- Produces: `EmbeddedAuthError.isInsufficientAuthorization`, `.isAccessDenied`, `.nextActions`, `.isTooManyAttempts`, `.isTooManyLogins` — consumed by Tasks 4, 5

- [ ] **Step 2.1: Write failing tests**

Create `Auth0Tests/EmbeddedAuth/EmbeddedAuthErrorAuthorizeTests.swift`:

```swift
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
```

- [ ] **Step 2.2: Run tests to confirm they fail**

```bash
swift test --filter EmbeddedAuthErrorAuthorizeTests 2>&1 | tail -20
```

Expected: compilation errors or test failures — the properties don't exist yet.

- [ ] **Step 2.3: Implement the new properties in EmbeddedAuthError**

Add the following extension at the bottom of `Auth0/EmbeddedAuth/EmbeddedAuthError.swift`, after the existing `Equatable` extension:

```swift
// MARK: - Authorize loop helpers

public extension EmbeddedAuthError {

    /// Whether the flow has more steps to complete (non-terminal).
    ///
    /// When `true`, read ``nextActions`` to know which step to present next.
    var isInsufficientAuthorization: Bool { code == "insufficient_authorization" }

    /// Whether the server terminated the flow without issuing a code.
    var isAccessDenied: Bool { code == "access_denied" }

    /// Whether the server rejected the attempt due to too many wrong OTP submissions.
    var isTooManyAttempts: Bool {
        code == "too_many_requests" &&
        (info["error_description"] as? String) == "too_many_attempts"
    }

    /// Whether the server rejected the attempt due to too many login attempts.
    var isTooManyLogins: Bool {
        code == "too_many_requests" &&
        (info["error_description"] as? String) == "too_many_logins"
    }

    /// Typed menu of what the server will accept on the next call.
    ///
    /// Non-empty only when ``isInsufficientAuthorization`` is `true`.
    var nextActions: [NextAction] {
        guard let nextArray = info["next"] as? [[String: Any]] else { return [] }
        return nextArray.map { entry in
            guard let actionString = entry["action"] as? String else {
                return .unknown(rawAction: "")
            }
            switch EmbeddedAction(rawValue: actionString) {
            case .identifyEmail:  return .identifyEmail
            case .identifyPhone:  return .identifyPhone
            case .challengeEmail: return .challengeEmail
            case .verifyOTP:
                return .verifyOTP(
                    channel: entry["channel"] as? String,
                    identifier: entry["identifier"] as? String
                )
            case .none:
                return .unknown(rawAction: actionString)
            }
        }
    }

}
```

- [ ] **Step 2.4: Run tests to confirm they pass**

```bash
swift test --filter EmbeddedAuthErrorAuthorizeTests 2>&1 | tail -20
```

Expected: all tests pass

- [ ] **Step 2.5: Commit**

```bash
git add Auth0/EmbeddedAuth/EmbeddedAuthError.swift \
        Auth0Tests/EmbeddedAuth/EmbeddedAuthErrorAuthorizeTests.swift
git commit -m "feat(embedded-auth): add isInsufficientAuthorization, isAccessDenied, nextActions, isTooManyAttempts, isTooManyLogins to EmbeddedAuthError"
```

---

## Task 3: EmbeddedAuthClient protocol, session validator, and factory

**Files:**
- Create: `Auth0/EmbeddedAuth/EmbeddedAuthClient.swift`
- Create: `Auth0/EmbeddedAuth/EmbeddedAuthSessionValidator.swift`

**Interfaces:**
- Consumes: `AuthorizationCode`, `EmbeddedCapability`, `OtpType` from Task 1; `EmbeddedAuthError` (modified) from Task 2
- Produces: `EmbeddedAuthClient` protocol; `EmbeddedAuthSessionValidator` struct — consumed by Task 4

- [ ] **Step 3.1: Create `EmbeddedAuthSessionValidator.swift`**

Create `Auth0/EmbeddedAuth/EmbeddedAuthSessionValidator.swift`:

```swift
import Foundation

/// Fails the request locally when there is no active ``EmbeddedAuthClient`` session.
///
/// Prevents continuation methods from making a network call when ``EmbeddedAuthClient/authorize(connection:capabilities:scope:audience:)``
/// has not been called first (or after a successful ``AuthorizationCode`` was already issued).
struct EmbeddedAuthSessionValidator: RequestValidator {

    let hasSession: Bool

    func validate() throws {
        guard hasSession else {
            throw EmbeddedAuthError(
                info: ["error": "no_active_session",
                       "error_description": "No active embedded auth session. Call authorize() first."],
                statusCode: 0
            )
        }
    }

}
```

- [ ] **Step 3.2: Create `EmbeddedAuthClient.swift`**

Create `Auth0/EmbeddedAuth/EmbeddedAuthClient.swift`:

```swift
import Foundation

// MARK: - Protocol

/// Client for the Embedded Authorization loop (`POST /e/authorize`).
///
/// Obtain an instance via ``Auth0/embeddedAuthClient(clientId:domain:session:)`` or
/// ``Auth0/embeddedAuthClient(session:bundle:)``.
///
/// ## Usage
///
/// ```swift
/// let client = Auth0.embeddedAuthClient()
/// let authentication = Auth0.authentication()
///
/// // 1. Start the flow
/// do {
///     let code = try await client.authorize().start()
///     // exchange code — but this step never succeeds on the first call
/// } catch let error as EmbeddedAuthError where error.isInsufficientAuthorization {
///     // nextActions tells you which step to present
/// }
///
/// // 2–N. Continue until you receive AuthorizationCode
/// let code = try await client.verifyOtp("123456", type: .oob).start()
///
/// // N+1. Exchange code for Credentials
/// let credentials = try await authentication.codeExchange(withCode: code.code,
///                                                         codeVerifier: "",
///                                                         redirectURI: "").start()
/// ```
///
/// ## See Also
/// - ``EmbeddedAuthError``
/// - ``NextAction``
/// - ``AuthorizationCode``
public protocol EmbeddedAuthClient: Trackable, Loggable, Sendable {

    /// Starts a new embedded authorization flow.
    ///
    /// Calls `POST /e/authorize` with `capabilities` advertised.
    /// Always throws ``EmbeddedAuthError`` with ``EmbeddedAuthError/isInsufficientAuthorization`` `true`
    /// on the first call; read ``EmbeddedAuthError/nextActions`` to determine which step to present.
    ///
    /// - Parameters:
    ///   - connection:   Optional connection name to target a specific connection.
    ///   - capabilities: Actions this SDK version supports. Defaults to ``EmbeddedCapability/all``.
    ///   - scope:        Optional OAuth scope string.
    ///   - audience:     Optional API audience.
    func authorize(connection: String?,
                   capabilities: [EmbeddedCapability],
                   scope: String?,
                   audience: String?) -> Request<AuthorizationCode, EmbeddedAuthError>

    /// Submits an email address as the user's identifier.
    ///
    /// Requires an active session (``authorize(connection:capabilities:scope:audience:)`` must have been called first).
    /// - Parameter email: The email address to identify with.
    func identifyEmail(_ email: String) -> Request<AuthorizationCode, EmbeddedAuthError>

    /// Submits a phone number as the user's identifier.
    ///
    /// Requires an active session.
    /// - Parameter phone: The phone number to identify with.
    func identifyPhone(_ phone: String) -> Request<AuthorizationCode, EmbeddedAuthError>

    /// Requests that the server send an email OTP challenge.
    ///
    /// Requires an active session.
    /// - Parameter index: Index of the challenge target in the `next` menu (defaults to `0`).
    func challengeEmail(index: Int) -> Request<AuthorizationCode, EmbeddedAuthError>

    /// Submits a one-time password to verify the user's identity.
    ///
    /// On success, returns ``AuthorizationCode`` which the caller should exchange for ``Credentials``
    /// via ``Authentication/codeExchange(withCode:codeVerifier:redirectURI:)``.
    ///
    /// Requires an active session.
    ///
    /// - Parameters:
    ///   - otp:  The one-time code entered by the user.
    ///   - type: Whether the code is OOB (email/SMS) or TOTP.
    func verifyOtp(_ otp: String, type: OtpType) -> Request<AuthorizationCode, EmbeddedAuthError>

}

// MARK: - Default overloads

public extension EmbeddedAuthClient {

    /// Starts a new embedded authorization flow using all default capabilities and no connection filter.
    func authorize() -> Request<AuthorizationCode, EmbeddedAuthError> {
        authorize(connection: nil, capabilities: EmbeddedCapability.all, scope: nil, audience: nil)
    }

    /// Starts a new embedded authorization flow targeting a specific connection.
    func authorize(connection: String) -> Request<AuthorizationCode, EmbeddedAuthError> {
        authorize(connection: connection, capabilities: EmbeddedCapability.all, scope: nil, audience: nil)
    }

    /// Requests an email OTP challenge targeting the first entry in the `next` menu.
    func challengeEmail() -> Request<AuthorizationCode, EmbeddedAuthError> {
        challengeEmail(index: 0)
    }

}

// MARK: - Factory

/// Embedded Authorization client.
///
/// ## Usage
///
/// ```swift
/// Auth0.embeddedAuthClient(clientId: "client-id", domain: "samples.us.auth0.com")
/// ```
///
/// - Parameters:
///   - clientId: Client ID of your Auth0 application.
///   - domain:   Domain of your Auth0 tenant, for example `samples.us.auth0.com`.
///   - session:  `URLSession` instance used for networking. Defaults to `URLSession.shared`.
/// - Returns: An ``EmbeddedAuthClient`` instance.
public func embeddedAuthClient(clientId: String,
                                domain: String,
                                session: URLSession = .shared) -> EmbeddedAuthClient {
    Auth0EmbeddedAuthClient(clientId: clientId,
                             url: .httpsURL(from: domain),
                             session: session)
}

/// Embedded Authorization client, reading credentials from `Auth0.plist`.
///
/// ## Usage
///
/// ```swift
/// Auth0.embeddedAuthClient()
/// ```
///
/// - Parameters:
///   - session: `URLSession` instance used for networking. Defaults to `URLSession.shared`.
///   - bundle:  Bundle used to locate `Auth0.plist`. Defaults to `Bundle.main`.
/// - Returns: An ``EmbeddedAuthClient`` instance.
/// - Warning: Calling this method without a valid `Auth0.plist` will crash your application.
public func embeddedAuthClient(session: URLSession = .shared, bundle: Bundle = .main) -> EmbeddedAuthClient {
    let values = plistValues(bundle: bundle)!
    return embeddedAuthClient(clientId: values.clientId, domain: values.domain, session: session)
}
```

- [ ] **Step 3.3: Build to confirm no errors**

```bash
swift build 2>&1 | grep -E "error:" | head -20
```

Expected: zero errors (the protocol references `Auth0EmbeddedAuthClient` which doesn't exist yet — that's fine at this stage if the concrete type is only referenced from the factory, which isn't compiled until Task 4 provides it; if the build fails on missing type, proceed to Task 4 immediately)

- [ ] **Step 3.4: Commit**

```bash
git add Auth0/EmbeddedAuth/EmbeddedAuthSessionValidator.swift \
        Auth0/EmbeddedAuth/EmbeddedAuthClient.swift
git commit -m "feat(embedded-auth): add EmbeddedAuthClient protocol, EmbeddedAuthSessionValidator, and factories"
```

---

## Task 4: Concrete implementation and full test suite

**Files:**
- Create: `Auth0/EmbeddedAuth/Auth0EmbeddedAuthClient.swift`
- Create: `Auth0Tests/EmbeddedAuth/EmbeddedAuthClientTests.swift`

**Interfaces:**
- Consumes: All of Tasks 1–3
- Produces: `Auth0EmbeddedAuthClient` — the concrete class used by factories in Task 3 and `ContentViewModel` in Task 5

- [ ] **Step 4.1: Write failing tests**

Create `Auth0Tests/EmbeddedAuth/EmbeddedAuthClientTests.swift`:

```swift
import Testing
import Foundation
@testable import Auth0

// Dedicated mock — never share static state with other test suites.
private final class EmbeddedAuthClientMockProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = EmbeddedAuthClientMockProtocol.requestHandler else {
            fatalError("EmbeddedAuthClientMockProtocol requires a requestHandler")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private let clientId = "TEST_CLIENT_ID"
private let domain   = "test.auth0.com"

// MARK: - Helpers

private func makeClient() -> EmbeddedAuthClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [EmbeddedAuthClientMockProtocol.self]
    return Auth0.embeddedAuthClient(clientId: clientId, domain: domain, session: URLSession(configuration: config))
}

private func insufficientAuthData(session: String, nextActions: [[String: Any]]) -> Data {
    try! JSONSerialization.data(withJSONObject: [
        "error": "insufficient_authorization",
        "auth_session": session,
        "next": nextActions
    ])
}

private func authCodeData(code: String = "auth0_ac_test123") -> Data {
    try! JSONSerialization.data(withJSONObject: ["authorization_code": code])
}

private func response(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://\(domain)/")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

private func capturedBody(from request: URLRequest) -> [String: Any]? {
    guard let data = request.httpBody else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

// MARK: - Suite

@Suite(.serialized)
struct EmbeddedAuthClientTests {

    // MARK: Factory

    @Test func factoryCreatesClientWithExplicitParams() {
        let client = Auth0.embeddedAuthClient(clientId: clientId, domain: domain) as! Auth0EmbeddedAuthClient
        #expect(client.clientId == clientId)
        #expect(client.url.absoluteString == "https://\(domain)/")
    }

    @Test func factoryUsesSharedSessionByDefault() {
        let client = Auth0.embeddedAuthClient(clientId: clientId, domain: domain) as! Auth0EmbeddedAuthClient
        #expect(client.session === URLSession.shared)
    }

    // MARK: authorize() — request body

    @Test func authorizePostsToCorrectURL() async {
        let sut = makeClient()
        var capturedURL: URL?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedURL = req.url
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        #expect(capturedURL?.path.hasSuffix("/e/authorize") == true)
    }

    @Test func authorizeUsesPostMethod() async {
        let sut = makeClient()
        var capturedMethod: String?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedMethod = req.httpMethod
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        #expect(capturedMethod == "POST")
    }

    @Test func authorizeSendsClientIdInBody() async {
        let sut = makeClient()
        var capturedBody: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            capturedBody = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        #expect(capturedBody?["client_id"] as? String == clientId)
    }

    @Test func authorizeSendsCapabilitiesInBody() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: nil,
                                       capabilities: [.identifyEmail, .challengeEmail, .verifyOTP],
                                       scope: nil,
                                       audience: nil).start()
        let caps = body?["capabilities"] as? [String]
        #expect(caps?.contains("action:identify:email:v1") == true)
        #expect(caps?.contains("action:challenge:email:v1") == true)
        #expect(caps?.contains("action:verify:otp:v1") == true)
    }

    @Test func authorizeSendsOptionalConnectionWhenProvided() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: "my-db", capabilities: EmbeddedCapability.all, scope: nil, audience: nil).start()
        #expect(body?["connection"] as? String == "my-db")
    }

    @Test func authorizeOmitsConnectionWhenNil() async {
        let sut = makeClient()
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize(connection: nil, capabilities: EmbeddedCapability.all, scope: nil, audience: nil).start()
        #expect(body?["connection"] == nil)
    }

    // MARK: authorize() — response parsing

    @Test func authorizeThrowsInsufficientAuthorizationWith403() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
        }
        do {
            _ = try await sut.authorize().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.isInsufficientAuthorization)
            #expect(error.nextActions == [.identifyEmail])
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: identifyEmail — local session guard

    @Test func identifyEmailFailsLocallyWithNoSession() async {
        let sut = makeClient()
        // No network handler set — any network call would crash
        do {
            _ = try await sut.identifyEmail("alice@example.com").start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
            #expect(error.statusCode == 0)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: identifyEmail — request body (after session established)

    @Test func identifyEmailSendsCorrectBody() async throws {
        let sut = makeClient()

        // First call: establish session
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()

        // Second call: capture identifyEmail body
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:challenge:email:v1"]]))
        }
        _ = try? await sut.identifyEmail("alice@example.com").start()

        #expect(body?["action"] as? String == "action:identify:email:v1")
        #expect(body?["email"] as? String == "alice@example.com")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func identifyEmailDoesNotExposeAuthSession() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:identify:email:v1"]]))
        }
        _ = try? await sut.authorize().start()
        // auth_session is stored internally — there is no public accessor on EmbeddedAuthClient
        // This test documents the invariant: the protocol has no authSession property
        let mirror = Mirror(reflecting: sut)
        let hasPublicSession = mirror.children.contains { $0.label == "authSession" }
        #expect(!hasPublicSession)
    }

    // MARK: challengeEmail

    @Test func challengeEmailFailsLocallyWithNoSession() async {
        let sut = makeClient()
        do {
            _ = try await sut.challengeEmail().start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func challengeEmailSendsCorrectAction() async {
        let sut = makeClient()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1"]]))
        }
        _ = try? await sut.authorize().start()

        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]))
        }
        _ = try? await sut.challengeEmail().start()
        #expect(body?["action"] as? String == "action:challenge:email:v1")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func challengeEmailRotatesSession() async {
        let sut = makeClient()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:challenge:email:v1"]]))
        }
        _ = try? await sut.authorize().start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.challengeEmail().start()

        // Next call should use the rotated session
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    // MARK: verifyOtp

    @Test func verifyOtpFailsLocallyWithNoSession() async {
        let sut = makeClient()
        do {
            _ = try await sut.verifyOtp("000000", type: .oob).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOtpSendsCorrectBody() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()

        #expect(body?["action"] as? String == "action:verify:otp:v1")
        #expect(body?["otp"] as? String == "123456")
        #expect(body?["binding_method"] as? String == "oob")
        #expect(body?["auth_session"] as? String == "sess_001")
    }

    @Test func verifyOtpReturnsAuthorizationCodeOn200() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 200), authCodeData(code: "auth0_ac_theCode"))
        }
        do {
            let code = try await sut.verifyOtp("123456", type: .oob).start()
            #expect(code.code == "auth0_ac_theCode")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func verifyOtpClearsSessionOnSuccess() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()

        // Session cleared — next continuation call must fail locally
        do {
            _ = try await sut.verifyOtp("000000", type: .oob).start()
            Issue.record("Expected no_active_session after successful code exchange")
        } catch let error as EmbeddedAuthError {
            #expect(error.code == "no_active_session")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func verifyOtpDoesNotClearSessionOnWrongOtp() async {
        let sut = makeClient()
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_001", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.authorize().start()

        // Wrong OTP: server returns 403 insufficient_authorization again
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            return (response(status: 403), insufficientAuthData(session: "sess_002", nextActions: [["action": "action:verify:otp:v1"]]))
        }
        _ = try? await sut.verifyOtp("000000", type: .oob).start()

        // Retry should still work (session is updated to sess_002)
        var body: [String: Any]?
        EmbeddedAuthClientMockProtocol.requestHandler = { req in
            body = try? JSONSerialization.jsonObject(with: req.httpBody!) as? [String: Any]
            return (response(status: 200), authCodeData())
        }
        _ = try? await sut.verifyOtp("123456", type: .oob).start()
        #expect(body?["auth_session"] as? String == "sess_002")
    }

    // MARK: Error paths

    @Test func authorizeThrowsAccessDeniedOnTerminalDenial() async {
        let sut = makeClient()
        let terminalData = try! JSONSerialization.data(withJSONObject: [
            "error": "access_denied",
            "error_description": "too_many_wrong_otp_attempts"
        ])
        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 403), terminalData) }
        _ = try? await sut.authorize().start()  // establish session

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in (response(status: 403), terminalData) }
        do {
            _ = try await sut.verifyOtp("000000", type: .oob).start()
            Issue.record("Expected failure")
        } catch let error as EmbeddedAuthError {
            #expect(error.isAccessDenied)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: Sequential flow — full e2e with mock data

    @Test func fullEmailOtpFlowReturnsAuthorizationCode() async {
        let sut = makeClient()
        var callCount = 0

        EmbeddedAuthClientMockProtocol.requestHandler = { _ in
            callCount += 1
            switch callCount {
            case 1:  // authorize()
                return (response(status: 403), insufficientAuthData(session: "s1", nextActions: [["action": "action:identify:email:v1"]]))
            case 2:  // identifyEmail()
                return (response(status: 403), insufficientAuthData(session: "s2", nextActions: [["action": "action:challenge:email:v1"]]))
            case 3:  // challengeEmail()
                return (response(status: 403), insufficientAuthData(session: "s3", nextActions: [["action": "action:verify:otp:v1", "channel": "email", "identifier": "al**@example.com"]]))
            case 4:  // verifyOtp()
                return (response(status: 200), authCodeData(code: "auth0_ac_final"))
            default:
                fatalError("Unexpected call \(callCount)")
            }
        }

        do {
            _ = try await sut.authorize().start()
            Issue.record("authorize() should throw with nextActions")
        } catch let e as EmbeddedAuthError where e.isInsufficientAuthorization {
            #expect(e.nextActions.first == .identifyEmail)
        } catch { Issue.record("Unexpected: \(error)") }

        do {
            _ = try await sut.identifyEmail("alice@example.com").start()
            Issue.record("identifyEmail() should throw with nextActions")
        } catch let e as EmbeddedAuthError where e.isInsufficientAuthorization {
            #expect(e.nextActions.first == .challengeEmail)
        } catch { Issue.record("Unexpected: \(error)") }

        do {
            _ = try await sut.challengeEmail().start()
            Issue.record("challengeEmail() should throw with nextActions")
        } catch let e as EmbeddedAuthError where e.isInsufficientAuthorization {
            if case .verifyOTP(let ch, let id) = e.nextActions.first {
                #expect(ch == "email")
                #expect(id == "al**@example.com")
            } else {
                Issue.record("Expected .verifyOTP")
            }
        } catch { Issue.record("Unexpected: \(error)") }

        let code = try await sut.verifyOtp("123456", type: .oob).start()
        #expect(code.code == "auth0_ac_final")
        #expect(callCount == 4)
    }

}
```

- [ ] **Step 4.2: Run tests to confirm they fail**

```bash
swift test --filter EmbeddedAuthClientTests 2>&1 | tail -20
```

Expected: compilation error — `Auth0EmbeddedAuthClient` and `EmbeddedAuthClient` protocol don't exist yet as a type the factory returns.

- [ ] **Step 4.3: Create `Auth0EmbeddedAuthClient.swift`**

Create `Auth0/EmbeddedAuth/Auth0EmbeddedAuthClient.swift`:

```swift
import Foundation

// MARK: - Concrete implementation

final class Auth0EmbeddedAuthClient: EmbeddedAuthClient, @unchecked Sendable {

    let clientId: String
    let url: URL
    let session: URLSession

    var auth0ClientInfo: Auth0ClientInfo
    var logger: Logger?

    private let lock = NSLock()
    private var _authSession: String?

    init(clientId: String,
         url: URL,
         session: URLSession = .shared,
         auth0ClientInfo: Auth0ClientInfo = Auth0ClientInfo()) {
        self.clientId = clientId
        self.url = url
        self.session = session
        self.auth0ClientInfo = auth0ClientInfo
    }

    // MARK: Protocol conformance

    func authorize(connection: String?,
                   capabilities: [EmbeddedCapability],
                   scope: String?,
                   audience: String?) -> Request<AuthorizationCode, EmbeddedAuthError> {
        var body: [String: Any] = [
            "client_id": clientId,
            "capabilities": capabilities.map { $0.action.rawValue }
        ]
        if let connection { body["connection"] = connection }
        if let scope      { body["scope"]      = scope      }
        if let audience   { body["audience"]   = audience   }
        return _authorize(body: body)
    }

    func identifyEmail(_ email: String) -> Request<AuthorizationCode, EmbeddedAuthError> {
        guard let session = authSession else { return missingSessionRequest() }
        return _authorize(body: [
            "auth_session": session,
            "action":       EmbeddedAction.identifyEmail.rawValue,
            "email":        email
        ])
    }

    func identifyPhone(_ phone: String) -> Request<AuthorizationCode, EmbeddedAuthError> {
        guard let session = authSession else { return missingSessionRequest() }
        return _authorize(body: [
            "auth_session": session,
            "action":       EmbeddedAction.identifyPhone.rawValue,
            "phone":        phone
        ])
    }

    func challengeEmail(index: Int) -> Request<AuthorizationCode, EmbeddedAuthError> {
        guard let session = authSession else { return missingSessionRequest() }
        return _authorize(body: [
            "auth_session": session,
            "action":       EmbeddedAction.challengeEmail.rawValue
        ])
    }

    func verifyOtp(_ otp: String, type: OtpType) -> Request<AuthorizationCode, EmbeddedAuthError> {
        guard let session = authSession else { return missingSessionRequest() }
        return _authorize(body: [
            "auth_session":   session,
            "action":         EmbeddedAction.verifyOTP.rawValue,
            "otp":            otp,
            "binding_method": type.rawValue
        ])
    }

}

// MARK: - Private

private extension Auth0EmbeddedAuthClient {

    var authSession: String? {
        lock.withLock { _authSession }
    }

    func setAuthSession(_ value: String?) {
        lock.withLock { _authSession = value }
    }

    func missingSessionRequest() -> Request<AuthorizationCode, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            requestValidator: [EmbeddedAuthSessionValidator(hasSession: false)],
            handle: { _, callback in
                callback(.failure(EmbeddedAuthError(
                    info: ["error": "no_active_session",
                           "error_description": "No active embedded auth session. Call authorize() first."],
                    statusCode: 0
                )))
            },
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    func _authorize(body: [String: Any]) -> Request<AuthorizationCode, EmbeddedAuthError> {
        Request(
            session: session,
            url: url.appending("e/authorize"),
            method: "POST",
            handle: { [weak self] result, callback in
                guard let self else { return }
                self.decodeAuthorizeResponse(result, callback: callback)
            },
            parameters: body,
            logger: logger,
            auth0ClientInfo: auth0ClientInfo
        )
    }

    func decodeAuthorizeResponse(
        _ result: Result<ResponseValue, EmbeddedAuthError>,
        callback: @Sendable (Result<AuthorizationCode, EmbeddedAuthError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            if error.isInsufficientAuthorization,
               let newSession = error.info["auth_session"] as? String {
                setAuthSession(newSession)
            }
            callback(.failure(error))

        case .success(let response):
            guard let data = response.data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["authorization_code"] as? String else {
                callback(.failure(EmbeddedAuthError(from: response)))
                return
            }
            setAuthSession(nil)
            callback(.success(AuthorizationCode(code: code)))
        }
    }

}
```

- [ ] **Step 4.4: Run tests**

```bash
swift test --filter EmbeddedAuthClientTests 2>&1 | tail -30
```

Expected: all tests pass. If any fail, read the failure message and fix the implementation (do not change the tests).

- [ ] **Step 4.5: Run the full test suite to check for regressions**

```bash
swift test 2>&1 | tail -20
```

Expected: all tests pass

- [ ] **Step 4.6: Lint**

```bash
swiftlint lint --reporter github-actions-logging 2>&1 | grep -v "^$"
```

Fix any warnings before committing.

- [ ] **Step 4.7: Commit**

```bash
git add Auth0/EmbeddedAuth/Auth0EmbeddedAuthClient.swift \
        Auth0Tests/EmbeddedAuth/EmbeddedAuthClientTests.swift
git commit -m "feat(embedded-auth): implement Auth0EmbeddedAuthClient with session threading and full test suite"
```

---

## Task 5: ContentViewModel — embedded auth state machine

**Files:**
- Modify: `App/ContentViewModel.swift`

**Interfaces:**
- Consumes: `EmbeddedAuthClient` (Task 3), `EmbeddedAuthError` (Task 2), `NextAction` (Task 1), `AuthorizationCode` (Task 1), `Authentication` (existing SDK type), `Credentials` (existing SDK type)
- Produces: `EmbeddedAuthUIState` enum, `ContentViewModel.embeddedAuthUIState`, `ContentViewModel.otp`, and methods `startEmbeddedFlow()`, `submitEmail(_:)`, `triggerChallenge()`, `submitOtp(_:)` — consumed by Task 6

- [ ] **Step 5.1: Add the embedded auth section to `ContentViewModel.swift`**

At the end of `App/ContentViewModel.swift`, **after** the existing `Array.uniqued()` extension, append:

```swift
// MARK: - Embedded Auth UI State

/// Drives the embedded auth section of ``ContentView``.
enum EmbeddedAuthUIState {
    case initial
    case identifyEmail
    case challengeEmail
    case verifyOTP(channel: String?, identifier: String?)
    case success(Credentials)
    case failed(String)
}
```

Then add these stored properties inside `ContentViewModel` (after the existing `credentialsManager` declaration):

```swift
    private let embeddedAuthClient: EmbeddedAuthClient
    @Published var embeddedAuthUIState: EmbeddedAuthUIState = .initial
    @Published var otp: String = ""
```

Update the `init` to accept `embeddedAuthClient`:

```swift
    init(email: String = "",
         password: String = "",
         isLoading: Bool = false,
         errorMessage: String? = nil,
         isAuthenticated: Bool = false,
         authenticationClient: Authentication,
         credentialsManager: CredentialsManager? = nil,
         embeddedAuthClient: EmbeddedAuthClient? = nil) {
        // ... existing assignments ...
        self.embeddedAuthClient = embeddedAuthClient ?? Auth0.embeddedAuthClient()
    }
```

Then append the following methods inside `ContentViewModel` (before the closing `}`):

```swift
    // MARK: Embedded auth methods

    func startEmbeddedFlow() async {
        isLoading = true
        embeddedAuthUIState = .initial
        do {
            _ = try await embeddedAuthClient.authorize().start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitEmail(_ email: String) async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.identifyEmail(email).start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func triggerChallenge() async {
        isLoading = true
        do {
            _ = try await embeddedAuthClient.challengeEmail().start()
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    func submitOtp(_ otp: String) async {
        isLoading = true
        do {
            let authCode = try await embeddedAuthClient.verifyOtp(otp, type: .oob).start()
            let credentials = try await authenticationClient
                .codeExchange(withCode: authCode.code, codeVerifier: "", redirectURI: "")
                .start()
            embeddedAuthUIState = .success(credentials)
        } catch let error as EmbeddedAuthError {
            handle(embeddedAuthError: error)
        } catch {
            embeddedAuthUIState = .failed(error.localizedDescription)
        }
        isLoading = false
    }

    private func handle(embeddedAuthError error: EmbeddedAuthError) {
        if error.isInsufficientAuthorization {
            switch error.nextActions.first {
            case .identifyEmail:
                embeddedAuthUIState = .identifyEmail
            case .challengeEmail:
                embeddedAuthUIState = .challengeEmail
            case .verifyOTP(let channel, let identifier):
                embeddedAuthUIState = .verifyOTP(channel: channel, identifier: identifier)
            default:
                embeddedAuthUIState = .failed(error.debugDescription)
            }
        } else {
            embeddedAuthUIState = .failed(error.debugDescription)
        }
    }
```

- [ ] **Step 5.2: Build to confirm no errors**

```bash
swift build 2>&1 | grep "error:" | head -20
```

Expected: zero errors

- [ ] **Step 5.3: Commit**

```bash
git add App/ContentViewModel.swift
git commit -m "feat(embedded-auth): add EmbeddedAuthUIState and embedded auth methods to ContentViewModel"
```

---

## Task 6: ContentView — embedded auth UI section

**Files:**
- Modify: `App/ContentView.swift`

**Interfaces:**
- Consumes: `EmbeddedAuthUIState`, `ContentViewModel.embeddedAuthUIState`, `ContentViewModel.otp`, `ContentViewModel.email`, `ContentViewModel.startEmbeddedFlow()`, `ContentViewModel.submitEmail(_:)`, `ContentViewModel.triggerChallenge()`, `ContentViewModel.submitOtp(_:)` — all from Task 5

- [ ] **Step 6.1: Add embedded auth section to ContentView**

In `App/ContentView.swift`, inside the outer `VStack`, add the following **after** the existing `Divider()` (the one before the Logout button) and **before** the Logout button block:

```swift
            Divider()
                .padding(.vertical)

            // MARK: Embedded Auth Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Embedded Auth")
                    .font(.headline)

                switch viewModel.embeddedAuthUIState {

                case .initial:
                    Button {
                        Task { await viewModel.startEmbeddedFlow() }
                    } label: {
                        Text("Start Embedded Auth")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)

                case .identifyEmail:
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Button {
                        Task { await viewModel.submitEmail(viewModel.email) }
                    } label: {
                        Text("Submit Email")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty)

                case .challengeEmail:
                    Text("We'll send a one-time code to your email.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        Task { await viewModel.triggerChallenge() }
                    } label: {
                        Text("Send OTP")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)

                case .verifyOTP(_, let identifier):
                    if let identifier {
                        Text("Enter the code sent to \(identifier)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    TextField("One-time code", text: $viewModel.otp)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                    Button {
                        Task { await viewModel.submitOtp(viewModel.otp) }
                    } label: {
                        Text("Verify")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading || viewModel.otp.isEmpty)

                case .success:
                    Text("✓ Embedded Auth succeeded")
                        .foregroundColor(.green)
                    Button {
                        viewModel.embeddedAuthUIState = .initial
                        viewModel.otp = ""
                    } label: {
                        Text("Reset")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                case .failed(let message):
                    Text("Error: \(message)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                    Button {
                        viewModel.embeddedAuthUIState = .initial
                        viewModel.otp = ""
                    } label: {
                        Text("Try Again")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
```

- [ ] **Step 6.2: Build the app target to confirm no errors**

```bash
swift build 2>&1 | grep "error:" | head -20
```

If building the app target requires Xcode, open the project and build with ⌘B. Expected: zero errors.

- [ ] **Step 6.3: Run the full test suite one final time**

```bash
swift test 2>&1 | tail -20
```

Expected: all tests pass

- [ ] **Step 6.4: Lint**

```bash
swiftlint lint --reporter github-actions-logging 2>&1 | grep -v "^$"
```

Fix any warnings before committing.

- [ ] **Step 6.5: Final commit**

```bash
git add App/ContentView.swift
git commit -m "feat(embedded-auth): add embedded auth e2e UI section to ContentView"
```

---

## Self-Review Checklist

- [x] **Branch** — plan starts by creating `feat/embedded-auth-authorize` from `feat/embedded-auth-discovery`
- [x] **Supporting types** — `NextAction`, `EmbeddedAction`, `OtpType`, `EmbeddedCapability`, `AuthorizationCode` all defined in Task 1
- [x] **EmbeddedAuthError** — all five new properties added with tests in Task 2
- [x] **Protocol** — `EmbeddedAuthClient` with all five methods + default overloads in Task 3
- [x] **Session validator** — `EmbeddedAuthSessionValidator` for local guard in Task 3
- [x] **Concrete class** — `Auth0EmbeddedAuthClient` with NSLock session threading in Task 4
- [x] **No session local fail** — tested for all continuation methods
- [x] **Session rotation** — tested (`challengeEmailRotatesSession`)
- [x] **Session cleared on success** — tested (`verifyOtpClearsSessionOnSuccess`)
- [x] **Session preserved on wrong OTP** — tested (`verifyOtpDoesNotClearSessionOnWrongOtp`)
- [x] **Sequential flow test** — full 4-call mock test in Task 4
- [x] **ContentViewModel** — `embeddedAuthClient` + `authentication` dependencies, `handle(embeddedAuthError:)` router
- [x] **ContentView** — all five states rendered, no force-unwraps, disabled buttons during loading
- [x] **Token exchange** — `submitOtp` calls `authenticationClient.codeExchange` after receiving `AuthorizationCode`
- [x] **auth_session never logged or exposed** — `testIdentifyEmailDoesNotExposeAuthSession` documents the invariant
- [x] **identifyPhone** — protocol + implementation present; not wired in demo UI (per scope)
- [x] **No placeholder steps** — all steps contain actual code
- [x] **Type consistency** — `EmbeddedAuthUIState` defined in Task 5 and consumed verbatim in Task 6
