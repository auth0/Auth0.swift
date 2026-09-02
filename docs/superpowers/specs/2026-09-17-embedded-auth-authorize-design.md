# Embedded Auth Authorize — Design Spec

| Field | Value |
|---|---|
| **Date** | 2026-09-17 |
| **Branch base** | `feat/embedded-auth-discovery` |
| **New branch** | `feat/embedded-auth-authorize` |
| **Design doc ref** | `Embedded Authorization — SDK Design.md` |

---

## Overview

Implement `POST /e/authorize` as the continuation engine for Embedded Authorization in Auth0.swift. The server drives a multi-step authentication loop; each POST either returns a `403 insufficient_authorization` with a `next` menu (continue) or a `200` with an `authorization_code` (loop complete). The SDK then hands the code to the caller, who exchanges it for `Credentials` via the existing `Authentication` protocol.

This spec covers:
1. New `EmbeddedAuthClient` protocol and concrete `Auth0EmbeddedAuthClient` implementation
2. Supporting types (`NextAction`, `EmbeddedAction`, `OtpType`, `EmbeddedCapability`, `AuthorizationCode`)
3. Extensions to `EmbeddedAuthError`
4. SwiftUI demo (`ContentViewModel` + `ContentView`) that wires both clients together
5. Tests (mocked URLProtocol) for each step and the full sequential flow

---

## Architecture

### Mental model

All five public methods hit the same `POST /e/authorize` endpoint with different request bodies. The concrete class has a single private `_authorize(body:)` that all public methods delegate to. Session (`auth_session`) is threaded automatically by the client; it is never exposed to the caller.

Token exchange (`/oauth/token`) is **not** done inside `EmbeddedAuthClient`. The `ContentViewModel` owns both `EmbeddedAuthClient` and `Authentication` and calls `authentication.codeExchange(...)` after receiving `AuthorizationCode`.

### Separation of concerns

```
EmbeddedAuthClient        — POST /e/authorize loop (stateful, session-aware)
Authentication            — POST /oauth/token (already exists; used as-is)
ContentViewModel          — orchestrates both; owns UI state machine
ContentView               — pure SwiftUI; driven entirely by published uiState
```

---

## New Files

### `Auth0/EmbeddedAuth/EmbeddedAuthClient.swift`

Protocol definition and factory functions.

```swift
public protocol EmbeddedAuthClient: Trackable, Loggable, Sendable {
    func authorize(connection: String?,
                   capabilities: [EmbeddedCapability],
                   scope: String?,
                   audience: String?) -> Request<AuthorizationCode, EmbeddedAuthError>

    func identifyEmail(_ email: String) -> Request<AuthorizationCode, EmbeddedAuthError>
    func identifyPhone(_ phone: String) -> Request<AuthorizationCode, EmbeddedAuthError>
    func challengeEmail(index: Int) -> Request<AuthorizationCode, EmbeddedAuthError>
    func verifyOtp(_ otp: String, type: OtpType) -> Request<AuthorizationCode, EmbeddedAuthError>
}

// Default overloads
extension EmbeddedAuthClient {
    func authorize(connection: String? = nil,
                   capabilities: [EmbeddedCapability] = EmbeddedCapability.all,
                   scope: String? = nil,
                   audience: String? = nil) -> Request<AuthorizationCode, EmbeddedAuthError>

    func challengeEmail() -> Request<AuthorizationCode, EmbeddedAuthError>  // index defaults to 0
}
```

Factory on `Auth0` namespace mirrors the existing `embeddedAuth()` factory pattern:
- `Auth0.embeddedAuthClient(clientId:domain:session:)`
- `Auth0.embeddedAuthClient(session:bundle:)` — reads from `Auth0.plist`

### `Auth0/EmbeddedAuth/Auth0EmbeddedAuthClient.swift`

Concrete implementation.

```swift
final class Auth0EmbeddedAuthClient: EmbeddedAuthClient, @unchecked Sendable {
    let clientId: String
    let url: URL
    let session: URLSession
    var auth0ClientInfo: Auth0ClientInfo
    var logger: Logger?

    // Thread-safe session store
    private let lock = NSLock()
    private var _authSession: String?

    // All public methods build a body dict and delegate here
    private func _authorize(body: [String: Any]) -> Request<AuthorizationCode, EmbeddedAuthError>
}
```

**Session rules (from design doc):**
- `auth_session` is set from every `403 insufficient_authorization` response (it may rotate).
- `auth_session` is cleared only after the token exchange **succeeds** (i.e., after `ContentViewModel` signals success — but since the exchange is external, the SDK clears it when it returns an `AuthorizationCode` successfully).
- Calling a continuation method (`identifyEmail`, etc.) with no active session fails locally with `EmbeddedAuthError(code: "no_active_session", statusCode: 0)` — no network call.

**Request body shapes:**

`authorize()` (initial call):
```json
{
  "client_id": "<id>",
  "capabilities": ["action:identify:email:v1", "action:challenge:email:v1", "action:verify:otp:v1"],
  "connection": "<optional>",
  "scope": "<optional>",
  "audience": "<optional>"
}
```

Continuation calls (`identifyEmail`, `challengeEmail`, `verifyOtp`):
```json
{
  "auth_session": "<opaque — set by SDK>",
  "action": "action:identify:email:v1",
  "<payload_key>": "<value>"
}
```

Payload keys per action:
- `identifyEmail` → `"email": <string>`
- `identifyPhone` → `"phone": <string>`
- `challengeEmail` → no extra payload
- `verifyOtp` → `"otp": <string>`, `"binding_method": <OtpType.rawValue>`

**Response decoder:**

Success (`200`):
```json
{ "authorization_code": "auth0_ac_…" }
```
→ Returns `AuthorizationCode(code: "auth0_ac_…")`. Clears `_authSession`.

Continuation (`403 insufficient_authorization`):
```json
{
  "error": "insufficient_authorization",
  "auth_session": "<rotated>",
  "next": [{ "action": "...", "channel": "...", "identifier": "..." }]
}
```
→ Updates `_authSession` from response. Calls back with `.failure(EmbeddedAuthError(...))`.

Terminal (`403 access_denied`, `429 too_many_requests`):
→ Does NOT update `_authSession`. Calls back with `.failure(...)`.

### `Auth0/EmbeddedAuth/EmbeddedAuthNextAction.swift`

All supporting types for the authorize loop.

```swift
// Return type for a completed authorization loop
public struct AuthorizationCode: Sendable {
    public let code: String
}

// Typed continuation menu — what the server accepts next
public enum NextAction: Sendable {
    case identifyEmail
    case identifyPhone
    case challengeEmail
    case verifyOTP(channel: String?, identifier: String?)
    case unknown(rawAction: String)
}

// Wire strings — used for capabilities advertisement and next-action parsing
public enum EmbeddedAction: String, Sendable {
    case identifyEmail  = "action:identify:email:v1"
    case identifyPhone  = "action:identify:phone:v1"
    case challengeEmail = "action:challenge:email:v1"
    case verifyOTP      = "action:verify:otp:v1"
}

// Capabilities the SDK advertises in the initial authorize call
public enum EmbeddedCapability: Sendable {
    case identifyEmail
    case identifyPhone
    case challengeEmail
    case verifyOTP

    public static let all: [EmbeddedCapability] = [.identifyEmail, .identifyPhone, .challengeEmail, .verifyOTP]

    var action: EmbeddedAction { /* maps to EmbeddedAction */ }
}

// OTP type for verifyOtp
public enum OtpType: String, Sendable {
    case oob  = "oob"   // Out-of-band (email, SMS, voice)
    case totp = "totp"  // TOTP authenticator app
}
```

---

## Modified Files

### `Auth0/EmbeddedAuth/EmbeddedAuthError.swift`

Add:

```swift
// Whether the flow has more steps (non-terminal)
public var isInsufficientAuthorization: Bool { code == "insufficient_authorization" }

// Whether the flow was terminated by the server
public var isAccessDenied: Bool { code == "access_denied" }

// Whether there were too many wrong OTP attempts
public var isTooManyAttempts: Bool {
    code == "too_many_requests" &&
    (info["error_description"] as? String) == "too_many_attempts"
}

// Whether there were too many login attempts
public var isTooManyLogins: Bool {
    code == "too_many_requests" &&
    (info["error_description"] as? String) == "too_many_logins"
}

// Typed menu of what the server will accept next (non-empty when isInsufficientAuthorization)
public var nextActions: [NextAction] { /* decode from info["next"] */ }
```

`nextActions` decodes the `next` array from the error response JSON. Each entry maps:
- `"action:identify:email:v1"` → `.identifyEmail`
- `"action:identify:phone:v1"` → `.identifyPhone`
- `"action:challenge:email:v1"` → `.challengeEmail`
- `"action:verify:otp:v1"` → `.verifyOTP(channel:identifier:)`
- anything else → `.unknown(rawAction:)`

---

## App Demo Files

### `App/ContentViewModel.swift`

```swift
enum EmbeddedAuthUIState {
    case initial
    case identifyEmail
    case challengeEmail
    case verifyOTP(channel: String?, identifier: String?)
    case success(Credentials)
    case failed(String)           // error message for display
}

@MainActor
final class ContentViewModel: ObservableObject {
    private let client: EmbeddedAuthClient
    private let authentication: Authentication

    @Published var uiState: EmbeddedAuthUIState = .initial

    init(client: EmbeddedAuthClient, authentication: Authentication)

    func startFlow() async          // calls client.authorize()
    func submitEmail(_ email: String) async
    func triggerChallenge() async   // calls client.challengeEmail()
    func submitOtp(_ otp: String) async   // on AuthorizationCode → authentication.codeExchange
}
```

Error routing helper (used by all methods):
```swift
private func handle(error: EmbeddedAuthError) {
    if error.isInsufficientAuthorization {
        switch error.nextActions.first {
        case .identifyEmail:    uiState = .identifyEmail
        case .challengeEmail:   uiState = .challengeEmail
        case .verifyOTP(let ch, let id): uiState = .verifyOTP(channel: ch, identifier: id)
        default:                uiState = .failed(error.debugDescription)
        }
    } else {
        uiState = .failed(error.debugDescription)
    }
}
```

`submitOtp` on success:
```swift
let credentials = try await authentication
    .codeExchange(withCode: authCode.code, codeVerifier: nil, redirectURI: "")
    .start()
uiState = .success(credentials)
```

### `App/ContentView.swift`

Switches on `viewModel.uiState`:
- `.initial` → "Start" button → calls `startFlow()`
- `.identifyEmail` → `TextField` for email + "Submit" button
- `.challengeEmail` → "Send OTP to my email" button
- `.verifyOTP(channel, identifier)` → shows masked identifier, `TextField` for OTP + "Verify" button
- `.success(credentials)` → shows access token prefix (for demo only — never log full token)
- `.failed(message)` → shows error message + "Retry" button back to `.initial`

---

## Test File

### `Auth0Tests/EmbeddedAuth/EmbeddedAuthClientTests.swift`

Uses a dedicated `EmbeddedAuthClientMockURLProtocol` (isolated static state, same pattern as `EmbeddedAuthTests`).

**Test groups:**

1. **Factory** — clientId/domain/session wiring
2. **authorize()** — sends correct body (clientId, capabilities), receives `insufficient_authorization` → `nextActions` parsed correctly
3. **identifyEmail()** — sends `auth_session` + `action` + `email`; fails locally (no session) without network
4. **challengeEmail()** — sends correct action; `auth_session` rotates
5. **verifyOtp()** — on `200` returns `AuthorizationCode`; on `403` parses `verifyOTP` nextAction with channel/identifier
6. **Error properties** — `isInsufficientAuthorization`, `isAccessDenied`, `isTooManyAttempts`, `isTooManyLogins`, `nextActions` decoding
7. **Sequential flow** — full `authorize → identifyEmail → challengeEmail → verifyOtp → AuthorizationCode` test using a stateful request handler

---

## Invariants

- `auth_session` is never exposed to callers or logged.
- Calling any continuation method without a session returns `no_active_session` locally (zero network calls).
- `capabilities` in the initial request defaults to `EmbeddedCapability.all`; callers can narrow.
- An unrecognised `action` in the `next` array is preserved as `.unknown(rawAction:)` — not dropped.
- `auth_session` is updated on every `insufficient_authorization` response (it may rotate per the spec).
- `auth_session` is cleared when `AuthorizationCode` is returned successfully.

---

## Out of Scope

- `identifyPhone` / phone challenge — protocol and types will be present, but the e2e demo only exercises the email flow.
- Biometric / passkey integration.
- Real network calls — all tests use `URLProtocol` mocks.
