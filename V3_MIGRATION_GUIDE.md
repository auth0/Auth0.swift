# v3 Migration Guide

> **Note:** This guide is actively maintained during the v3 development phase. As new changes are merged, this document will be updated to reflect the latest breaking changes and migration steps.

Auth0.swift v3 includes many significant changes:

- Updated default values for better out-of-the-box behavior.
- Behavior changes to improve developer experience:
  - Consistent main thread callback execution for UI updates.
- Methods added for supporting new features


As expected with a major release, Auth0.swift v3 contains breaking changes. Please review this guide thoroughly to understand the changes required to migrate your application to v3.

---

## Table of Contents

- [**Dependency Updates**](#dependency-updates)
  + [JWTDecode.swift](#jwtdecodeswift)
- [**Default Values Changed**](#default-values-changed)
  + [Scope](#scope)
  + [Credentials Manager minTTL](#credentials-manager-minttl)
  + [Signup connection](#signup-connection)
- [**Behavior Changes**](#behavior-changes)
  + [Completion callbacks](#completion-callbacks)
- [**Methods Added**](#methods-added)
  + [Web Auth](#web-auth)
- [**Swift 6 Concurrency**](#swift-6-concurrency)
  + [Sendable protocol conformances](#sendable-protocol-conformances)
- [**API Changes**](#api-changes)
  + [WebAuthError cases](#webautherror-cases)
  + [Renamed APIs](#renamed-apis)
  + [Request to Requestable](#request-to-requestable)
  + [ID Token Validation](#id-token-validation)
- [**Removed APIs**](#removed-apis)
  + [Management API client (Users)](#management-api-client-users)

---

## Dependency Updates

### JWTDecode.swift

**Change:** The JWTDecode.swift dependency has been upgraded from v3.3.0 to v4.0.0.

**Impact:** JWTDecode.swift v4.0.0 is fully Swift 6 compliant with complete concurrency support. This upgrade ensures Auth0.swift is ready for Swift 6 adoption and provides better thread-safety guarantees when working with JWTs.

**Action Required:** No code changes are required in your application.

---

## Default Values Changed

### Scope

**Change:** The default scope value now includes `offline_access`.

The default scope value was changed from `openid profile email` to `openid profile email offline_access`. This change applies to Web Auth and all Authentication client methods (except `renew(withRefreshToken:scope:)`, in which `scope` keeps defaulting to `nil`).

**Impact:** If your application doesn't need refresh tokens, you should explicitly specify the scope without `offline_access`.

<details>
  <summary>Migration example</summary>

```swift
// v2 - offline_access had to be explicitly added
Auth0
    .webAuth()
    .scope("openid profile email offline_access")
    .start { result in
        // ...
    }

// v3 - offline_access is included by default
Auth0
    .webAuth()
    .start { result in
        // ...
    }

// v3 - opt out of offline_access if not needed
Auth0
    .webAuth()
    .scope("openid profile email")
    .start { result in
        // ...
    }
```
</details>

**Reason:** Mobile apps typically rely on refresh tokens to maintain user sessions over extended periods. Since default values should reflect the most common usage scenarios, the default scope now includes `offline_access`.

### Credentials Manager minTTL

**Change:** The default `minTTL` value changed from `0` to `60` seconds.

This change affects the following Credentials Manager methods:

- `credentials(withScope:minTTL:parameters:headers:callback:)`
- `credentials(withScope:minTTL:parameters:headers:)` (async/await)
- `credentials(withScope:minTTL:parameters:headers:)` (Combine)
- `apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)`
- `apiCredentials(forAudience:scope:minTTL:parameters:headers:)` (async/await)
- `apiCredentials(forAudience:scope:minTTL:parameters:headers:)` (Combine)

**Impact:** Credentials will be renewed if they expire within 60 seconds, instead of only when already expired.

<details>
  <summary>Migration example</summary>

```swift
// v2 - minTTL defaulted to 0, had to be set explicitly
credentialsManager.credentials(minTTL: 60) { result in
    // ...
}

// v3 - minTTL defaults to 60 seconds
credentialsManager.credentials { result in
    // ...
}

// v3 - use 0 to restore v2 behavior
credentialsManager.credentials(minTTL: 0) { result in
    // ...
}
```
</details>

**Reason:** A `minTTL` of `0` meant credentials were not renewed until expired, which could result in delivering access tokens that expire immediately after retrieval, causing subsequent API requests to fail. Setting a default value of `60` seconds ensures the access token remains valid for a reasonable period.

### Signup connection

**Change:** The `connection` parameter now defaults to `"Username-Password-Authentication"`.

This change affects the following Authentication client method:

- `signup(email:username:password:connection:userMetadata:rootAttributes:)`

**Impact:** You no longer need to specify the connection parameter if you're using the default database connection.

<details>
  <summary>Migration example</summary>

```swift
// v2 - connection had to be specified
Auth0
    .authentication()
    .signup(email: email,
            username: username,
            password: password,
            connection: "Username-Password-Authentication")
    .start { result in
        // ...
    }

// v3 - connection parameter is optional
Auth0
    .authentication()
    .signup(email: email,
            username: username,
            password: password)
    .start { result in
        // ...
    }

// v3 - specify connection if using a different one
Auth0
    .authentication()
    .signup(email: email,
            username: username,
            password: password,
            connection: "custom-database")
    .start { result in
        // ...
    }
```
</details>

**Reason:** By default, new Auth0 tenants have a database connection called `Username-Password-Authentication`. Since it's the default database connection name that many customers use, having it as the default reduces boilerplate.

## Behavior Changes

### Completion callbacks

**Change:** All completion callbacks now execute on the main thread.

In v2, completion callbacks would sometimes execute on the main thread and sometimes on background threads, depending on where `URLSession` completed the network request. In v3, all completion callbacks are guaranteed to execute on the main thread.

**Affected APIs:**

- All Authentication API methods using callbacks
- All Credentials Manager methods using callbacks
- All Web Auth methods using callbacks

**Impact:** If your code performs CPU-intensive work in callbacks, you should explicitly dispatch to a background queue.

<details>
  <summary>Migration example</summary>

```swift
// v2 - thread was unpredictable, had to dispatch to main for UI updates
credentialsManager.credentials { result in
    DispatchQueue.main.async {
        self.updateUI(result)
    }
}

// v3 - already on main thread
credentialsManager.credentials { result in
    self.updateUI(result)
}

// v3 - dispatch to background for CPU-intensive work
credentialsManager.credentials { result in
    DispatchQueue.global().async {
        let processed = self.performExpensiveOperation(result)
        DispatchQueue.main.async {
            self.updateUI(processed)
        }
    }
}
```
</details>

**Reason:** After performing operations with Auth0.swift, it's common to run presentation logic – for example, to show an error or navigate to the main flow of the app. Having callbacks execute on the main thread by default improves developer experience and reduces boilerplate.

## Methods Added

### Web Auth

Auth0.swift will use a current key window to present the in-app browser for Web Auth. When using ASWebAuthenticationSession, it will grab a key window and use it as the ASPresentationAnchor. With SFSafariViewController, Auth0.swift will present it using the topmost view controller in this key window. While this approach works well for single-window apps, on multi-window apps the in-app browser may show up in a different window than expected. Auth0.swift now supports passing a custom window in which to present the in-app browser. For this reason, the following method is added to the Web Auth builder:

- `presentationWindow(_ window:)`

<details>
  <summary>Code</summary>

```swift
Auth0
    .webAuth()
    .presentationWindow(window)
    .start { result in
        // ...
    }
```
</details>

---

## Swift 6 Concurrency

v3 adopts Swift 6 strict concurrency by adding `Sendable` conformances across the SDK. If your application defines custom types conforming to SDK protocols, some changes may be required.

### Sendable protocol conformances

**Change:** `Auth0Error` and `Logger` now inherit from `Sendable`.

```swift
// v3
public protocol Auth0Error: LocalizedError, CustomDebugStringConvertible, Sendable { ... }
public protocol Logger: Sendable { ... }
```

**Impact:** If your application defines a custom type that conforms to either protocol, that type must now also conform to `Sendable`.

<details>
  <summary>Migration example</summary>

```swift
// v2 - no Sendable requirement on conforming types
struct MyAppError: Auth0Error {
    var cause: Error?
    var debugDescription: String { "my error" }
    var errorDescription: String? { "my error" }
}

struct MyLogger: Logger {
    func trace(request: URLRequest, session: URLSession) { ... }
    func trace(response: URLResponse, data: Data?) { ... }
    func trace(url: URL, source: String?) { ... }
}

// v3 - conforming types must be Sendable
// For structs with only Sendable stored properties, conformance is automatic:
struct MyAppError: Auth0Error { // implicitly Sendable - no changes needed
    var cause: Error?
    var debugDescription: String { "my error" }
    var errorDescription: String? { "my error" }
}

// For classes or types with non-Sendable stored properties, add @unchecked Sendable
// and ensure thread safety manually:
final class MyLogger: Logger, @unchecked Sendable {
    private let lock = NSLock()
    // ... thread-safe implementation
}
```
</details>

---

## API Changes

### WebAuthError cases

**Change:** WebAuthError has been refined to provide more actionable error information:

**Removed cases** (now return `.unknown` with descriptive messages):
- `.noBundleIdentifier` - Configuration error that should be caught during development
- `.noAuthorizationCode` - Rare edge case in PKCE flow
- `.invalidInvitationURL` - Configuration error for organization invitations
- `.pkceNotAllowed` - Configuration error (Application Type must be "Native" and Token Endpoint Authentication Method must be "None"). This error happens at most once when integrating the SDK into the app

**New cases**:
- `.authenticationFailed` - Server-side authentication failures (wrong password, MFA required, account locked, etc.)
- `.codeExchangeFailed` - Token exchange failures (network issues, invalid grant, backend errors, etc.)

**Impact:** Error handling code needs to be updated to use the new error cases. The removed cases will now throw `.unknown` errors with descriptive messages.

**Reason:** The removed error cases represent configuration issues that should be caught during development, not handled in production code. This will result in a more useful and meaningful set of WebAuthError cases.

### Renamed APIs

The following APIs have been renamed to align with the Android, Flutter, and React Native Auth0 SDKs:

| v2 | v3 |
| --- | --- |
| `clearSession(federated:)` | `logout(federated:)` |
| `UserInfo` | `UserProfile` |
| `Credentials.expiresIn` | `Credentials.expiresAt` |
| `APICredentials.expiresIn` | `APICredentials.expiresAt` |
| `SSOCredentials.expiresIn` | `SSOCredentials.expiresAt` |
| `Telemetry` | `Auth0ClientInfo` |

**`clearSession()` → `logout()`**

The `clearSession(federated:)` method on the Web Auth client has been renamed to `logout(federated:)`. This affects all three API flavors: callback-based, Combine, and async/await.

<details>
  <summary>Migration example</summary>

```swift
// v2
Auth0
    .webAuth()
    .clearSession { result in
        // ...
    }

try await Auth0.webAuth().clearSession()

// v3
Auth0
    .webAuth()
    .logout { result in
        // ...
    }

try await Auth0.webAuth().logout()
```
</details>

**`UserInfo` → `UserProfile`**

The `UserInfo` struct has been renamed to `UserProfile`. The `userInfo(withAccessToken:)` method name on the Authentication client is unchanged, as it maps to the OIDC `/userinfo` endpoint.

<details>
  <summary>Migration example</summary>

```swift
// v2
let user: UserInfo = ...

// v3
let user: UserProfile = ...
```
</details>

**`expiresIn` → `expiresAt`**

The `expiresIn` property on `Credentials`, `APICredentials`, and `SSOCredentials` has been renamed to `expiresAt`. The JSON key (`expires_in`) and Keychain storage key are unchanged.

<details>
  <summary>Migration example</summary>

```swift
// v2
let expiry = credentials.expiresIn

// v3
let expiry = credentials.expiresAt
```
</details>

**`Telemetry` → `Auth0ClientInfo`**

The `Telemetry` struct has been renamed to `Auth0ClientInfo`, and the `telemetry` property on `Trackable` conforming types has been renamed to `auth0ClientInfo`.

<details>
  <summary>Migration example</summary>

```swift
// v2
var auth = Auth0.authentication()
auth.telemetry.enabled = false

// v3
var auth = Auth0.authentication()
auth.auth0ClientInfo.enabled = false
```
</details>

## Request to Requestable

**Change:** All `Authentication` and `MFAClient` methods now return protocol types instead of the concrete `Request` struct:

- Credential-returning methods return `any TokenRequestable<T, E>` (extends `Requestable`, adds `.validateClaims()` and related modifiers — see [ID Token Validation](#id-token-validation) below).
- All other methods (e.g. `signup`, `resetPassword`, `userInfo`, `jwks`) return `any Requestable<T, E>`.

**Impact:** Existing call sites that call `.start(_:)` directly are unaffected. The main benefit is that mocking the `Authentication` layer in tests no longer requires `URLProtocol` — you can implement the protocol directly.

**Reason:** With the previous concrete `Request` return type, the only way to intercept Auth0 calls in tests was by stubbing at the URL session layer. Protocol return types let you supply a lightweight mock implementation directly.

<details>
  <summary>Mocking example</summary>

```swift
// Conforming type for credential-returning methods (TokenRequestable)
struct MockTokenRequest: TokenRequestable {
    typealias ResultType = Credentials
    typealias ErrorType = AuthenticationError

    let mockResult: Result<Credentials, AuthenticationError>

    func start(_ callback: @escaping (Result<Credentials, AuthenticationError>) -> Void) {
        callback(mockResult)
    }

    func validateClaims() -> any TokenRequestable<Credentials, AuthenticationError> { self }
    func withLeeway(_ leeway: Int) -> any TokenRequestable<Credentials, AuthenticationError> { self }
    func withIssuer(_ issuer: String) -> any TokenRequestable<Credentials, AuthenticationError> { self }
    func withNonce(_ nonce: String?) -> any TokenRequestable<Credentials, AuthenticationError> { self }
    func withMaxAge(_ maxAge: Int?) -> any TokenRequestable<Credentials, AuthenticationError> { self }
    func withOrganization(_ organization: String?) -> any TokenRequestable<Credentials, AuthenticationError> { self }
}

class MockAuthentication: Authentication {
    let mockResult: Result<Credentials, AuthenticationError>

    init(mockResult: Result<Credentials, AuthenticationError>) {
        self.mockResult = mockResult
    }

    func login(email: String, code: String, audience: String?, scope: String)
        -> any TokenRequestable<Credentials, AuthenticationError> {
        return MockTokenRequest(mockResult: mockResult)
    }
}

// Test
func testLoginSuccess() {
    let mockCredentials = Credentials(accessToken: "token", tokenType: "Bearer",
                                      expiresAt: Date(), idToken: "id_token")
    let mockAuth = MockAuthentication(mockResult: .success(mockCredentials))

    mockAuth.login(email: "test@example.com", code: "123456", audience: nil, scope: "openid")
        .start { result in
            XCTAssertEqual(try? result.get().accessToken, "token")
        }
}
```
</details>
### ID Token Validation

**Change:** All credential-returning methods on `Authentication` and `MFAClient` now return `any TokenRequestable<T, E>`. `TokenRequestable` extends `Requestable` and adds opt-in ID token claim validation via a chainable builder API.

**Existing call sites that call `.start(_:)` directly are unaffected.**

<details>
  <summary>Usage example</summary>

```swift
// Basic — validate with defaults
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken)
    .validateClaims()
    .start { result in ... }

// Custom options
Auth0
    .authentication()
    .codeExchange(withCode: code, codeVerifier: verifier, redirectURI: redirectURI)
    .validateClaims()
    .withLeeway(120)                           // 2-minute clock skew
    .withNonce("expected-nonce")
    .withOrganization("org_abc123")
    .start { result in ... }
```
</details>

Chain any combination of the following modifiers after `validateClaims()`:

| Modifier | Default | Description |
| --- | --- | --- |
| `.withLeeway(_ leeway: Int)` | `60` s | Clock-skew tolerance in **seconds**. |
| `.withIssuer(_ issuer: String)` | Auth0 domain URL | Expected `iss` claim. |
| `.withNonce(_ nonce: String?)` | `nil` (skip) | Expected `nonce` claim. |
| `.withMaxAge(_ maxAge: Int?)` | `nil` (skip) | Maximum seconds since last authentication (`auth_time`). |
| `.withOrganization(_ organization: String?)` | `nil` (skip) | Expected `org_id` or `org_name` claim. |

> **Note:** When using Web Auth (PKCE flow), ID token validation is performed automatically. You do not need to call `validateClaims()` yourself.

> **Note:** If `validateClaims()` is enabled but the response does not contain an ID token, the request fails with `AuthenticationError` wrapping `IDTokenDecodingError.missingIDToken` rather than silently succeeding.

**Affected methods** (now return `any TokenRequestable` instead of `any Requestable`):

- `Authentication.login(email:code:audience:scope:)`
- `Authentication.login(phoneNumber:code:audience:scope:)`
- `Authentication.login(usernameOrEmail:password:realmOrConnection:audience:scope:)`
- `Authentication.loginDefaultDirectory(withUsername:password:audience:scope:)`
- `Authentication.login(withOTP:mfaToken:)`
- `Authentication.login(withOOBCode:mfaToken:bindingCode:)`
- `Authentication.login(withRecoveryCode:mfaToken:)`
- `Authentication.login(appleAuthorizationCode:fullName:profile:audience:scope:)`
- `Authentication.login(facebookSessionAccessToken:profile:audience:scope:)`
- `Authentication.login(passkey:challenge:connection:audience:scope:)` (both `LoginPasskey` and `SignupPasskey` variants)
- `Authentication.codeExchange(withCode:codeVerifier:redirectURI:)`
- `Authentication.ssoExchange(withRefreshToken:)`
- `Authentication.renew(withRefreshToken:audience:scope:)`
- `MFAClient.verify(oobCode:bindingCode:mfaToken:)`
- `MFAClient.verify(otp:mfaToken:)`
- `MFAClient.verify(recoveryCode:mfaToken:)`

**Impact:** No migration required for existing call sites. If you implement the `Authentication` protocol in your own mocks or test doubles, update the return type of the affected methods from `any Requestable<Credentials, AuthenticationError>` to `any TokenRequestable<Credentials, AuthenticationError>` (see the [mocking example](#request-to-requestable) above).

---

## Removed APIs

### Management API client (Users)

> [!NOTE]
> This section only impacts you if your app used the Management API client (`Auth0.users(...)`). Removing it makes the SDK **leaner** — all consumers benefit from a smaller binary without carrying code they don't use.

**Change:** The Management API client has been removed. This includes the `Auth0.users(token:domain:)` and `Auth0.users(token:session:bundle:)` factory functions, the `Users` protocol, `ManagementError`, `ManagementResult`, and `UserPatchAttributes`.

**Impact:** Any code that calls `Auth0.users(...)` or references the removed types will no longer compile.

**Migration:** Instead of calling the [Management API](https://auth0.com/docs/api/management/v2) directly from your mobile app, expose dedicated endpoints in your own backend that perform the required operations, and call those from the app using the access token you already have.

For example, if you were reading or updating user metadata:

1. **Create a backend endpoint** (e.g. `PATCH /me/metadata`) that accepts the operation your app needs.
2. **Call that endpoint from your app**, passing the user's access token as a `Bearer` token in the `Authorization` header.
3. **On your backend**, obtain a machine-to-machine token via the [Client Credentials flow](https://auth0.com/docs/get-started/authentication-and-authorization-flow/client-credentials-flow) and use it to call the [Management API](https://auth0.com/docs/api/management/v2) with the precise scopes required.

**Reason:** The Management API is not designed for direct use from mobile apps — it is heavily restricted for public clients (only a small subset of operations are permitted, and sensitive actions such as managing roles, rules, or other users are not available). It also requires its own audience (`https://YOUR_AUTH0_DOMAIN/api/v2/`), and each individual access token is scoped to a single audience. If your app also needs to call your own backend API, you must set that API's identifier as the audience at login, which means the same token cannot be used for the Management API.

---
[Go up ⤴](#table-of-contents)
