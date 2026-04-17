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
  + [Credentials Manager error handling](#credentials-manager-error-handling)
- [**Methods Added**](#methods-added)
  + [Web Auth](#web-auth)
  + [Credentials Manager clearAll](#credentials-manager-clearall)
  + [CredentialsStorage deleteAllEntries](#credentialsstorage-deleteallentries)
- [**Swift 6 Concurrency**](#swift-6-concurrency)
  + [Sendable protocol conformances](#sendable-protocol-conformances)
  + [WebAuth is now Sendable](#webauth-is-now-sendable)
  + [Sendable conformances for Web Auth typealiases](#sendable-conformances-for-web-auth-typealiases)
  + [@MainActor callback parameters](#mainactor-callback-parameters)
  + [@MainActor on async Web Auth methods](#mainactor-on-async-web-auth-methods)
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

**Change:** All completion callbacks are now annotated `@MainActor` and are guaranteed to execute on the main thread.

In v2, completion callbacks would sometimes execute on the main thread and sometimes on background threads, depending on where `URLSession` completed the network request. In v3, all completion callbacks are annotated `@MainActor`, giving both a compile-time guarantee and a runtime guarantee that the callback executes on the main thread.

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

### Credentials Manager error handling

**Change:** `CredentialsManager` storage methods now throw errors instead of returning `Bool` or optional `Data`.

The following methods have been updated:

| v2 | v3 |
| --- | --- |
| `store(credentials:) -> Bool` | `store(credentials:) throws` |
| `clear() -> Bool` | `clear() throws` |
| `clear(forAudience:scope:) -> Bool` | `clear(forAudience:scope:) throws` |
| `store(apiCredentials:forAudience:forScope:)` (silent failure) | `store(apiCredentials:forAudience:forScope:) throws` |
| `user` (property, returns `UserProfile?`) | `userProfile()` (throwing function, returns `UserProfile?`) |

The `CredentialsStorage` protocol methods have also changed:

| v2 | v3 |
| --- | --- |
| `getEntry(forKey:) -> Data?` | `getEntry(forKey:) throws -> Data` |
| `setEntry(_:forKey:) -> Bool` | `setEntry(_:forKey:) throws` |
| `deleteEntry(forKey:) -> Bool` | `deleteEntry(forKey:) throws` |

**Impact:** Any code that checks the `Bool` return value of `store` or `clear` must be updated to use `do-try-catch`. Code that ignores the return value (e.g. `_ = credentialsManager.store(...)`) can be migrated to `try?` if you want to continue ignoring failures, or wrapped in `do-try-catch` to handle them. If you have a custom `CredentialsStorage` implementation, you must update your method signatures and throw an error instead of returning `false` or `nil`.

<details>
  <summary>Migration example — store and clear</summary>

```swift
// v2
if credentialsManager.store(credentials: credentials) {
    // stored successfully
} else {
    // handle failure
}

if credentialsManager.clear() {
    // cleared successfully
} else {
    // handle failure
}

// v3
do {
    try credentialsManager.store(credentials: credentials)
    // stored successfully
} catch {
    // handle error
}

do {
    try credentialsManager.clear()
    // cleared successfully
} catch {
    // handle error
}

// v3 — if you want to silently ignore failures (not recommended)
try? credentialsManager.store(credentials: credentials)
try? credentialsManager.clear()
```
</details>

<details>
  <summary>Migration example — custom CredentialsStorage</summary>

```swift
// v2
class MyCustomStorage: CredentialsStorage {
    func getEntry(forKey key: String) -> Data? {
        return myStore[key]
    }
    func setEntry(_ data: Data, forKey key: String) -> Bool {
        myStore[key] = data
        return true
    }
    func deleteEntry(forKey key: String) -> Bool {
        myStore.removeValue(forKey: key)
        return true
    }
}

// v3
class MyCustomStorage: CredentialsStorage {
    func getEntry(forKey key: String) throws -> Data {
        guard let data = myStore[key] else {
            throw MyStorageError.itemNotFound
        }
        return data
    }
    func setEntry(_ data: Data, forKey key: String) throws {
        myStore[key] = data
    }
    func deleteEntry(forKey key: String) throws {
        guard myStore[key] != nil else {
            throw MyStorageError.itemNotFound
        }
        myStore.removeValue(forKey: key)
    }
}
```
</details>

**Downstream impact on async methods:** Because `clear()` and `store(credentials:)` now surface errors, several callback-based methods gain new failure paths that were previously silent:

| Method | New error delivered to callback | Trigger |
| --- | --- | --- |
| `revoke(headers:callback:)` | `.noCredentials` | `getEntry(forKey:)` throws (e.g. item not found). In v2 this returned `.success` |
| `revoke(headers:callback:)` | `.clearFailed` | Keychain delete fails after a successful token revocation, or when no refresh token is present |
| `credentials(withScope:minTTL:parameters:headers:callback:)` | `.noCredentials` | `getEntry(forKey:)` throws when reading stored credentials |
| `credentials(withScope:minTTL:parameters:headers:callback:)` | `.storeFailed` | Keychain write fails when saving renewed credentials |
| `renew(parameters:headers:callback:)` | `.noCredentials` | `getEntry(forKey:)` throws when reading stored credentials |
| `renew(parameters:headers:callback:)` | `.storeFailed` | Keychain write fails when saving renewed credentials |
| `apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)` | `.noCredentials` | `getEntry(forKey:)` throws when reading stored credentials |
| `apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)` | `.storeFailed` | Keychain write fails when saving exchanged API credentials |
| `ssoCredentials(parameters:headers:callback:)` | `.noCredentials` | `getEntry(forKey:)` throws when reading stored credentials |
| `ssoCredentials(parameters:headers:callback:)` | `.storeFailed` | Keychain write fails when saving updated credentials after SSO exchange |

In v2, storage read failures were swallowed by `try?` — for example, `revoke()` returned `.success` when no credentials were stored and `getEntry(forKey:)` threw. In v3, the underlying storage error is propagated as the `cause` of the `CredentialsManagerError`, giving callers full context to respond appropriately.

Additionally, the `user` property has been replaced with the `userProfile()` method that now throws errors instead of silently returning `nil`:

| Method | Error thrown | Trigger |
| --- | --- | --- |
| `userProfile()` | `.noCredentials` | `getEntry(forKey:)` throws (e.g. item not found) or ID token cannot be decoded |

<details>
  <summary>Migration example — userProfile error handling</summary>

```swift
// v2 — storage/decoding failures were silently swallowed
let user = credentialsManager.user  // nil on any failure

// v3 — errors are now propagated
do {
    let user = try credentialsManager.userProfile()
    print("User profile: \(user)")
} catch {
    // handle storage or decoding error
    print("Failed to retrieve user profile: \(error)")
}

// v3 — if you want to preserve v2 behavior (not recommended)
let user = try? credentialsManager.userProfile()
```
</details>

<details>
  <summary>Migration example — handling new revoke failure path</summary>

```swift
// v2 — storage failures were silently ignored;
//       revoke returned .success even when nothing was stored
credentialsManager.revoke { result in
    switch result {
    case .success:
        navigateToLogin()
    case .failure(let error):
        // only .revokeFailed was possible here
        showError(error)
    }
}

// v3 — storage errors are now surfaced
credentialsManager.revoke { result in
    switch result {
    case .success:
        navigateToLogin()
    case .failure(let error):
        switch error {
        case CredentialsManagerError.noCredentials:
            // no credentials in storage (getEntry threw) — nothing to revoke
            navigateToLogin()
        case CredentialsManagerError.revokeFailed:
            // network revocation failed — refresh token may still be active
            showError(error)
        case CredentialsManagerError.clearFailed:
            // token was revoked but credentials could not be removed from storage
            // treat as logged out since the token is no longer valid
            navigateToLogin()
        default:
            showError(error)
        }
    }
}
```
</details>

**Reason:** Returning `Bool` or `nil` silently swallows the underlying Keychain error, making it impossible to distinguish a missing item from a permissions failure or a corrupted entry. Throwing the error directly gives callers full context to respond appropriately—for example, by prompting the user to re-authenticate or surfacing a meaningful error message.

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

### Credentials Manager clearAll

**New method:** `clearAll() throws` has been added to `CredentialsManager`.

This method removes **all** entries managed by the Credentials Manager from the Keychain (its configured storage/service), including the default credentials entry and any API credentials stored via `store(apiCredentials:)`. It also resets the biometric authentication session (if biometric authentication was enabled).

This is different from the existing `clear()` method, which only removes the default credentials entry.

<details>
  <summary>Code</summary>

```swift
// Clear only the default credentials entry (existing method)
let cleared = credentialsManager.clear()

// Clear ALL keychain entries managed by the Credentials Manager (new method)
do {
    try credentialsManager.clearAll()
} catch {
    print("Failed to clear all credentials: \(error)")
}
```
</details>

**Impact:** This is a new additive API. No migration is required. Use it when you need to completely wipe all stored credentials (e.g., on account deletion or full sign-out).

### CredentialsStorage deleteAllEntries

**New method:** `deleteAllEntries() throws` has been added to the `CredentialsStorage` protocol with a default implementation that triggers an `assertionFailure`.

If you're using a custom `CredentialsStorage` and plan to call `clearAll()`, you'll need to implement `deleteAllEntries()` in your custom storage — otherwise it will trigger an assertion failure. If you're not using `clearAll()`, no migration is required.

<details>
  <summary>Migration example</summary>

```swift
// v2 - CredentialsStorage protocol
class MyCustomCredentialStorage: CredentialsStorage {
    func getEntry(forKey key: String) -> Data? { ... }
    func setEntry(_ data: Data, forKey key: String) -> Bool { ... }
    func deleteEntry(forKey key: String) -> Bool { ... }
}

// v3 - Implement deleteAllEntries() if you plan to use clearAll()
class MyCustomCredentialStorage: CredentialsStorage {
    func getEntry(forKey key: String) -> Data? { ... }
    func setEntry(_ data: Data, forKey key: String) -> Bool { ... }
    func deleteEntry(forKey key: String) -> Bool { ... }

    func deleteAllEntries() throws {
        // Delete all entries from your custom storage
    }
}
```
</details>

**Impact:** If you have a custom `CredentialsStorage` implementation and use `clearAll()`, you must implement the `deleteAllEntries()` method. If you don't use `clearAll()`, no changes are needed — the default implementation will only trigger an assertion if called. The default `SimpleKeychain`-based storage already provides this implementation.

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

### WebAuth is now Sendable

**Change:** The `WebAuth` protocol now inherits from `Sendable`.

```swift
// v3
public protocol WebAuth: SenderConstraining, Trackable, Loggable, Sendable { ... }
```

**Impact — custom `WebAuth` implementations:** If your application defines a custom type conforming to `WebAuth` (for example, a mock or test double), that type must now also conform to `Sendable`.

<details>
  <summary>Migration example</summary>

```swift
// v2 - no Sendable requirement
class MockWebAuth: WebAuth {
    // ...
}

// v3 - must be Sendable
// For structs with only Sendable stored properties, conformance is automatic:
struct MockWebAuth: WebAuth { // implicitly Sendable - no changes needed
    // ...
}

// For classes, add @unchecked Sendable and ensure thread safety manually:
final class MockWebAuth: WebAuth, @unchecked Sendable {
    private let lock = NSLock()
    // ... thread-safe implementation
}
```
</details>

**Impact — builder methods now return copies:** In v2, `Auth0WebAuth` was a `final class`, so builder methods mutated the instance in place. In v3 it is a `struct`, so each builder method returns a new copy without modifying the original.

**If you use method chaining, no change is needed:**

```swift
// ✅ Works the same in v2 and v3
Auth0.webAuth()
    .scope("openid")
    .audience("https://api.example.com")
    .start { result in ... }
```

**If you call builder methods imperatively, you must assign the return value:**

```swift
// ⚠️ Broken in v3 — audience is called but its return value is discarded,
// so it is never applied. In v2 this worked silently because Auth0WebAuth
// was a class and the method mutated the instance in place.
// Note: in v2 this pattern would also have produced a "result unused" compiler warning.
var webAuth = Auth0.webAuth().scope("openid")
webAuth.audience("https://api.example.com")
webAuth.start { result in ... }

// ✅ Fixed — reassign the return value
var webAuth = Auth0.webAuth().scope("openid")
webAuth = webAuth.audience("https://api.example.com")
webAuth.start { result in ... }
```

---

### Sendable conformances for Web Auth typealiases

**Change:** The following public typealiases have been updated for Swift 6 concurrency:

| Symbol | v2 | v3 |
|--------|----|----|
| `WebAuthProviderCallback` | `(WebAuthResult<Void>) -> Void` | `@Sendable (WebAuthResult<Void>) -> Void` |
| `WebAuthProvider` | `(_ url: URL, _ callback: @escaping WebAuthProviderCallback) -> WebAuthUserAgent` | `@Sendable @MainActor (_ url: URL, _ callback: @escaping WebAuthProviderCallback) -> WebAuthUserAgent` |

**`WebAuthProviderCallback` — now `@Sendable`**

**Impact:** If you pass a closure as a `WebAuthProviderCallback`, all values it captures must be `Sendable`. In most cases this is automatically satisfied, but if your closure captures a non-`Sendable` class you will get a compiler warning under strict concurrency.

**`WebAuthProvider` — now `@Sendable @MainActor`**

**Impact:** If you implement a custom `WebAuthProvider`, the closure is now `@MainActor` — its body runs on the main actor. `MyUserAgent.init` is therefore called on the main actor; the init does not need to be `@MainActor` itself, but it must not be isolated to a different actor.

Since custom providers always present UI, they should already be doing UI work on the main thread. In most cases no code changes are required — Swift infers `@Sendable @MainActor` from the `WebAuthProvider` typealias automatically.

<details>
  <summary>Migration example</summary>

```swift
// v2
let myProvider: WebAuthProvider = { url, callback in
    let agent = MyUserAgent(url: url, callback: callback)
    return agent
}

// v3 - Swift infers @Sendable @MainActor from the WebAuthProvider typealias.
// The closure body runs on the main actor, so MyUserAgent.init is called there.
// MyUserAgent does not need to be @MainActor, but it must conform to Sendable.
let myProvider: WebAuthProvider = { url, callback in
    let agent = MyUserAgent(url: url, callback: callback)
    return agent
}
```
</details>

### @MainActor callback parameters

**Change:** All public callback parameters are now `@MainActor`. This affects the following APIs:

- `Requestable.start(_:)`, `TokenRequestable.start(_:)`
- `WebAuth.start(_:)`, `WebAuth.logout(federated:callback:)`, `WebAuth.onClose(_:)`
- `CredentialsManager.credentials(withScope:minTTL:parameters:headers:callback:)`, `revoke(headers:_:)`, `apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)`, `ssoCredentials(parameters:headers:callback:)`, `renew(parameters:headers:callback:)`

**Impact:**

- **Call sites** — No changes required for typical trailing closures. Swift infers `@MainActor` from the parameter type automatically. Most callbacks already perform UI work on the main thread, so this is a no-op in practice.

- **Custom protocol implementations** (mocks, test doubles) — If you implement `Requestable`, `TokenRequestable`, `WebAuth`, or any other protocol whose method signatures include a callback, you must add `@MainActor` on the matching parameter.

<details>
  <summary>Migration example</summary>

```swift
// v2 - start without @MainActor
struct MockRequestable: Requestable {
    func start(_ callback: @escaping (Result<Credentials, AuthenticationError>) -> Void) {
        callback(.success(mockCredentials))
    }
    // ...
}

// v3 - add @MainActor to match the updated protocol requirement
struct MockRequestable: Requestable {
    func start(_ callback: @escaping @MainActor (Result<Credentials, AuthenticationError>) -> Void) {
        Task { @MainActor in callback(.success(mockCredentials)) }
    }
    // ...
}
```
</details>

### @MainActor on async Web Auth methods

**Change:** The async/await variants of `start()` and `logout(federated:)` on the `WebAuth` protocol are now `@MainActor`:

```swift
// v3
@MainActor func start() async throws -> Credentials
@MainActor func logout(federated: Bool) async throws
```

**Impact:**

- **Most callers — no action required.** Calling a `@MainActor async` function from any async context is transparent: Swift automatically hops to the main actor at the `await` point and returns to the caller's executor when done.

```swift
// Works unchanged from any async context
let credentials = try await Auth0.webAuth().start()
try await Auth0.webAuth().logout()
```

- **Custom `WebAuth` conformances (mocks, test doubles)** — Add `@MainActor` to your `start()` and `logout(federated:)` implementations to match the updated protocol requirement.

<details>
  <summary>Migration example</summary>

```swift
// v2
struct MockWebAuth: WebAuth {
    func start() async throws -> Credentials { ... }
    func logout(federated: Bool) async throws { ... }
}

// v3
struct MockWebAuth: WebAuth {
    @MainActor func start() async throws -> Credentials { ... }
    @MainActor func logout(federated: Bool) async throws { ... }
}
```
</details>

- **Callers using `any WebAuth` (protocol existential)** — The `@MainActor` constraint is now enforced at the call site through the protocol. Under strict concurrency, Swift will emit a warning if you call these methods from a non-isolated context without `await`.

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

    func start(_ callback: @escaping @MainActor (Result<Credentials, AuthenticationError>) -> Void) {
        Task { @MainActor in callback(mockResult) }
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

**Affected methods** (now return `any TokenRequestable` instead of `Request`):

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

**Impact:** No migration required for existing call sites. If you implement the `Authentication` protocol in your own mocks or test doubles, update the return type of the affected methods from `Request<Credentials, AuthenticationError>` to `any TokenRequestable<Credentials, AuthenticationError>` (see the [mocking example](#request-to-requestable) above).

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
