# v3 Migration Guide

Auth0.swift v3 is a Swift 6-ready release with improved error handling, predictable threading, and a cleaner API surface:

- **Swift 6 concurrency:** `Sendable` conformances, `@MainActor` callbacks, and `@Sendable` closures across all public APIs — including a JWTDecode.swift v4 upgrade.
- **Throwing storage methods:** `CredentialsManager` and `CredentialsStorage` methods now throw instead of returning `Bool` or `nil`, so failures are never silently swallowed.
- **Guaranteed main-thread delivery:** All callback, Combine, and async/await variants deliver results on the main thread — no more `DispatchQueue.main.async` boilerplate.
- **Updated defaults:** Scope now includes `offline_access`, `minTTL` defaults to 60 seconds, and `signup` defaults the `connection` to `"Username-Password-Authentication"`.
- **Renamed APIs** for consistency with the Android, Flutter, and React Native Auth0 SDKs.
- **New APIs:** Multi-window Web Auth support, `clearAll()`, automatic credentials management, and ID token validation.
- **Removed APIs:** The Management API client and the deprecated MFA methods on the `Authentication` protocol have been removed.

---

## Table of Contents

- [**Swift 6 Concurrency**](#swift-6-concurrency)
  + [WebAuth is now Sendable](#webauth-is-now-sendable)
  + [Sendable protocol conformances](#sendable-protocol-conformances)
  + [Sendable conformances for Web Auth typealiases](#sendable-conformances-for-web-auth-typealiases)
  + [@MainActor callback parameters](#mainactor-callback-parameters)
  + [@MainActor on async Web Auth methods](#mainactor-on-async-web-auth-methods)
  + [JWTDecode.swift upgraded to v4.0.0](#jwtdecodeswift-upgraded-to-v400)
- [**Default Values Changed**](#default-values-changed)
  + [Scope](#scope)
  + [Credentials Manager minTTL](#credentials-manager-minttl)
  + [Signup connection](#signup-connection)
- [**Behavior Changes**](#behavior-changes)
  + [Main thread result delivery](#main-thread-result-delivery)
  + [DPoP validation errors](#dpop-validation-errors)
- [**Credentials Manager: storage methods now throw**](#credentials-manager-storage-methods-now-throw)
- [**Methods Added**](#methods-added)
  + [Web Auth — multi-window support](#web-auth)
  + [Automatic credentials management in Web Auth](#automatic-credentials-management-in-web-auth)
  + [Credentials Manager clearAll](#credentials-manager-clearall)
  + [CredentialsStorage deleteAllEntries](#credentialsstorage-deleteallentries)
- [**API Changes**](#api-changes)
  + [WebAuthError cases](#webautherror-cases)
  + [Renamed APIs](#renamed-apis)
  + [Request to Requestable](#request-to-requestable)
  + [ID Token Validation](#id-token-validation)
- [**Removed APIs**](#removed-apis)
  + [Management API client (Users)](#management-api-client-users)
  + [MFA methods on Authentication protocol](#mfa-methods-on-authentication-protocol)
- [**Getting Help**](#getting-help)

---

## Swift 6 Concurrency

The `Auth0` library target is now compiled with Swift 6 language mode, enforcing strict concurrency. v3 adopts this by adding `Sendable` conformances across the SDK. If your application defines custom types conforming to SDK protocols, some changes may be required.

### WebAuth is now Sendable

> [!IMPORTANT]
> `Auth0WebAuth` has been changed from a `final class` to a `struct`. This change does **not** produce a compilation error — your existing code will continue to build — but it silently changes the behavior of any code that calls builder methods imperatively (without chaining). Review the usage patterns below to ensure your integration behaves as expected.

**Change:** The `WebAuth` protocol now inherits from `Sendable`, and the concrete `Auth0WebAuth` implementation has been changed from a `final class` to a `struct`.

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

### Sendable conformances for Web Auth typealiases

> [!NOTE]
> This section only applies if you implement a **custom `WebAuthProvider`** — i.e. you replace the default browser (ASWebAuthenticationSession) with your own using `.provider(_:)` on the Web Auth builder. Most apps do not do this and can skip this section.

**Change:** The following public typealiases have been updated for Swift 6 concurrency:

| Symbol | v2 | v3 |
|--------|----|----|
| `WebAuthProviderCallback` | `(WebAuthResult<Void>) -> Void` | `@Sendable (WebAuthResult<Void>) -> Void` |
| `WebAuthProvider` | `(_ url: URL, _ callback: @escaping WebAuthProviderCallback) -> WebAuthUserAgent` | `@Sendable @MainActor (_ url: URL, _ callback: @escaping WebAuthProviderCallback) -> WebAuthUserAgent` |

**`WebAuthProviderCallback` — now `@Sendable`**

**Impact:** The `callback` parameter your `WebAuthProvider` closure receives is a `WebAuthProviderCallback`. If you store it inside your custom user agent, any values the closure captures must be `Sendable`. In most cases this is automatically satisfied, but if your closure captures a non-`Sendable` class the compiler will flag it — as a **warning** in Swift 5 with `-strict-concurrency=complete`, or as a **build error** in Swift 6 language mode.

<details>
  <summary>Migration example — non-Sendable capture</summary>

```swift
// ❌ Compiler warning — MyBrowserDelegate is not Sendable
class MyBrowserDelegate {
    func browserDidFinish() { ... }
}

let delegate = MyBrowserDelegate()
let callback: WebAuthProviderCallback = { result in
    delegate.browserDidFinish() // ⚠️ capture of non-Sendable type
}

// ✅ Fix — mark the class as Sendable
final class MyBrowserDelegate: Sendable {
    func browserDidFinish() { ... }
}

// ✅ Or isolate to @MainActor (since browser callbacks are UI work)
@MainActor
class MyBrowserDelegate {
    func browserDidFinish() { ... }
}
```
</details>

**`WebAuthProvider` — now `@Sendable @MainActor`**

**Impact:** If you implement a custom `WebAuthProvider`, the closure is now `@MainActor` — its body runs on the main actor. `MyUserAgent.init` is therefore called on the main actor; the init does not need to be `@MainActor` itself, but it must not be isolated to a different actor.

Since custom providers always present UI, they should already be doing UI work on the main thread. In most cases no code changes are required — Swift infers `@Sendable @MainActor` from the `WebAuthProvider` typealias automatically.

<details>
  <summary>Migration example — custom WebAuthProvider</summary>

```swift
// v2
let myProvider: WebAuthProvider = { url, callback in
    let agent = MyUserAgent(url: url, callback: callback)
    return agent
}

// v3 — no code change needed. Swift infers @Sendable @MainActor from the
// WebAuthProvider typealias. MyUserAgent.init runs on the main actor
// and MyUserAgent must conform to Sendable.
let myProvider: WebAuthProvider = { url, callback in
    let agent = MyUserAgent(url: url, callback: callback)
    return agent
}
```
</details>

### @MainActor callback parameters

**Change:** All public callback parameters are now `@MainActor`. This affects the following APIs:

- `Requestable.start(_:)`, `TokenRequestable.start(_:)` — covers all `Authentication`, `MFAClient`, and `MyAccount` / `MyAccountAuthenticationMethods` methods, which return these protocol types
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

- **Callers using `any WebAuth` (protocol existential)** — The `@MainActor` constraint is now enforced at the call site through the protocol. Under strict concurrency, Swift will emit a warning if you call these methods from a non-isolated context without `await`.

### JWTDecode.swift upgraded to v4.0.0

**Change:** The JWTDecode.swift dependency has been upgraded from v3.3.0 to v4.0.0.

**Impact:** JWTDecode.swift v4.0.0 is fully Swift 6 compliant. No code changes are required in your application.

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

---

## Behavior Changes

### Main thread result delivery

**Change:** All three API variants — callback, Combine, and async/await — now guarantee that results are delivered on the main thread.

Any method returning `Requestable` or `TokenRequestable` delivers its result on the main thread regardless of which variant you use:

| Variant | How main thread delivery is guaranteed |
| --- | --- |
| **Callback** | The callback parameter is annotated `@MainActor`, giving both a compile-time and runtime guarantee. |
| **Combine** | The publisher wraps the `@MainActor` callback variant, so the `Future` promise resolves on the main actor and subscribers always receive values and completions on the main thread. |
| **Async/await** | The `start()` method is annotated `@MainActor`, so it always resumes on the main actor. |

In v2, completion callbacks would sometimes execute on the main thread and sometimes on background threads, depending on where `URLSession` completed the network request. The Combine and async/await variants inherited the same unpredictable threading. In v3, all three variants guarantee main thread delivery.

**Affected APIs:**

- All Authentication API methods (callback, Combine, and async/await)
- All Credentials Manager methods (callback, Combine, and async/await)
- All Web Auth methods (callback, Combine, and async/await)
- All My Account API methods (callback, Combine, and async/await)

**Impact:** If your code performs CPU-intensive work in callbacks or Combine subscribers, you should explicitly dispatch to a background queue. You no longer need `DispatchQueue.main.async` or `.receive(on: DispatchQueue.main)` when consuming results from Auth0.swift.

<details>
  <summary>Migration example — callback</summary>

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

<details>
  <summary>Migration example — Combine</summary>

```swift
// v2 - had to use receive(on:) to ensure main thread delivery
Auth0
    .authentication()
    .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication")
    .start()
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { completion in
        // ...
    }, receiveValue: { credentials in
        self.updateUI(credentials)
    })
    .store(in: &cancellables)

// v3 - receive(on:) is no longer needed, results are already on the main thread
Auth0
    .authentication()
    .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication")
    .start()
    .sink(receiveCompletion: { completion in
        // ...
    }, receiveValue: { credentials in
        self.updateUI(credentials)
    })
    .store(in: &cancellables)
```
</details>

<details>
  <summary>Migration example — async/await</summary>

```swift
// v2 - start() could resume on any thread; had to hop to main for UI work
Task {
    let credentials = try await Auth0
        .authentication()
        .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication")
        .start()
    await MainActor.run {
        self.updateUI(credentials)
    }
}

// v3 - start() is @MainActor, so it always resumes on the main thread
Task {
    let credentials = try await Auth0
        .authentication()
        .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication")
        .start()
    self.updateUI(credentials) // already on main thread
}
```
</details>

**Reason:** After performing operations with Auth0.swift, it's common to run presentation logic – for example, to show an error or navigate to the main flow of the app. Guaranteeing main thread delivery across all three API variants improves developer experience and eliminates an entire class of threading bugs.

### DPoP validation errors

When DPoP-bound credentials are stored, the Credentials Manager now validates the DPoP state before attempting renewal. The following new errors can be thrown by `credentials()`, `apiCredentials()`, and `ssoCredentials()`:

> [!NOTE]
> These errors are only relevant if you are using DPoP support. Ensure you handle these errors when migrating to v3.

| Error | Trigger | Affected methods |
| --- | --- | --- |
| `.dpopNotConfigured` | Stored credentials are DPoP-bound but the `Authentication` client was not configured with `.useDPoP()`. | `credentials()`, `apiCredentials()`, `ssoCredentials()` |
| `.dpopKeyMissing` | Stored credentials are DPoP-bound but the DPoP key pair is no longer available in the Keychain. | `credentials()`, `apiCredentials()`, `ssoCredentials()` |
| `.dpopKeyMismatch` | Stored credentials are DPoP-bound but the current DPoP key pair does not match the one used when credentials were saved. | `credentials()`, `apiCredentials()`, `ssoCredentials()` |

Additionally, `store(credentials:)` now persists the DPoP thumbprint alongside credentials when the `Authentication` client is configured with DPoP. This allows the Credentials Manager to detect key changes across app launches.

<details>
  <summary>Migration example — handling DPoP validation errors</summary>

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials):
        // use credentials
        break
    case .failure(let error):
        switch error {
        case .dpopNotConfigured:
            // Developer forgot to call useDPoP() on the Authentication client
            // passed to the credentials manager. Fix the client configuration.
            // e.g.:
            CredentialsManager(authentication: Auth0.authentication().useDPoP())
        case .dpopKeyMissing:
            // DPoP key was lost. Clear local state and prompt user to re-authenticate
        case .dpopKeyMismatch:
            // DPoP key exists but doesn't match the one used at login (key rotation). Clear local state and prompt user to re-authenticate
        default:
            showError(error)
        }
    }
}
```
</details>

---

## Credentials Manager: storage methods now throw

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
    // Storage failed — the underlying Keychain error is available via `error`.
    // The user is still authenticated (credentials are valid in memory),
    // but they will be prompted to log in again on the next app launch.
    // Report to your error monitoring service (e.g. Sentry, Crashlytics, Datadog):
    //   Sentry.capture(error: error)
    //   Crashlytics.crashlytics().record(error: error)
}

do {
    try credentialsManager.clear()
    // cleared successfully
} catch {
    // Keychain delete failed. Treat the user as logged out regardless —
    // the session is no longer usable.
    // Report to your error monitoring service (e.g. Sentry, Crashlytics, Datadog):
    //   Sentry.capture(error: error)
    //   Crashlytics.crashlytics().record(error: error)
    navigateToLogin()
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

| Error | Trigger | Affected methods |
| --- | --- | --- |
| `.noCredentials` | **New in v3:** `getEntry(forKey:)` throws when reading stored credentials (e.g. item not found). In v2 this was swallowed by `try?` — `revoke()` even returned `.success` when nothing was stored. `.noCredentials` already existed in v2 but was only thrown when stored data couldn't be decoded; it now also fires when the Keychain read itself fails. | `credentials()`, `renew()`, `apiCredentials()`, `ssoCredentials()`, `revoke()` |
| `.storeFailed` | Keychain write fails when saving renewed or exchanged credentials. | `credentials()`, `renew()`, `apiCredentials()`, `ssoCredentials()` |
| `.clearFailed` | Keychain delete fails after successful token revocation, or when no refresh token is present. | `revoke()` |

In v3, the underlying storage error is propagated as the `cause` of the `CredentialsManagerError`, giving callers full context to respond appropriately.

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

Auth0.swift uses the current key window to present the in-app browser for Web Auth. When using ASWebAuthenticationSession, it grabs the key window and uses it as the ASPresentationAnchor; with SFSafariViewController, it presents using the topmost view controller in that window. While this works well for single-window apps, multi-window apps may see the in-app browser appear in an unexpected window. Auth0.swift now supports passing a custom window for presentation. The following methods are added to the Web Auth builder:

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

### Automatic credentials management in Web Auth

**New method:** `useCredentialsManager(_ credentialsManager:)` — pass a `CredentialsManager` instance to the Web Auth client to automatically store credentials after a successful login and clear them after a successful logout.

> [!NOTE]
> `useCredentialsManager(_:)` is optional. If you prefer to store and clear credentials manually after login and logout, you can continue to do so without calling this method.

**Impact:** If your app was manually storing credentials after login or clearing them after logout, you can now pass your `CredentialsManager` to the Web Auth client and remove that manual code. If you were using a custom `CredentialsStorage` (e.g., for a custom Keychain configuration), you can pass a `CredentialsManager` initialized with that storage and it will be used automatically.

<details>
  <summary>Migration example: default storage</summary>

```swift
// v2 - had to manually store credentials after login
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

Auth0
    .webAuth()
    .start { result in
        switch result {
        case .success(let credentials):
            try? credentialsManager.store(credentials: credentials)
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }

// v2 - had to manually clear credentials after logout
Auth0
    .webAuth()
    .clearSession { result in
        switch result {
        case .success:
            try? credentialsManager.clear()
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }

// v3 - pass the CredentialsManager and credentials are stored/cleared automatically
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

Auth0
    .webAuth()
    .useCredentialsManager(credentialsManager)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
            // Credentials are already stored automatically
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }

Auth0
    .webAuth()
    .useCredentialsManager(credentialsManager)
    .logout { result in
        switch result {
        case .success:
            print("Logged out")
            // Credentials are already cleared automatically
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```
</details>

<details>
  <summary>Migration example: custom storage</summary>

If you were already using a custom `CredentialsStorage` implementation (for example, a custom Keychain configuration), simply pass the `CredentialsManager` with your custom storage to the Web Auth client.

```swift
// v2 - custom storage with manual store/clear
let customStorage = MyCustomKeychainStorage()
let credentialsManager = CredentialsManager(
    authentication: Auth0.authentication(),
    storage: customStorage
)

Auth0
    .webAuth()
    .start { result in
        switch result {
        case .success(let credentials):
            try? credentialsManager.store(credentials: credentials)
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }

// v3 - pass the CredentialsManager with custom storage
let customStorage = MyCustomKeychainStorage()
let credentialsManager = CredentialsManager(
    authentication: Auth0.authentication(),
    storage: customStorage
)

Auth0
    .webAuth()
    .useCredentialsManager(credentialsManager)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
            // Credentials are stored using your custom storage automatically
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```
</details>

> [!NOTE]
> If the credentials manager fails to store or clear credentials, a `WebAuthError.credentialsManagerError` will be thrown. The underlying error can be accessed via the `cause` property.

> [!IMPORTANT]
> You **must** call `useCredentialsManager(_:)` on both your `start()` and `logout()` call chains — omitting it on `logout()` will succeed but credentials will **not** be cleared automatically. Do **not** manually call `store(credentials:)` after login or `clear()` after logout on the same instance; the Web Auth client handles this automatically and doing so can lead to race conditions or inconsistent state.
>
> ```swift
> // ✅ Credentials will be cleared automatically
> Auth0.webAuth().useCredentialsManager(credentialsManager).logout { ... }
> ```

**Reason:** Many apps need to store credentials after login and clear them after logout. The `useCredentialsManager(_:)` method reduces boilerplate and prevents common mistakes such as forgetting to store or clear credentials.

### Credentials Manager clearAll

**New method:** `clearAll() throws` has been added to `CredentialsManager`.

This method removes **all** entries managed by the Credentials Manager from the Keychain (its configured storage/service), including the default credentials entry and any API credentials stored via `store(apiCredentials:)`. It also resets the biometric authentication session (if biometric authentication was enabled).

This is different from the existing `clear()` method, which only removes the default credentials entry.

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
    func getEntry(forKey key: String) throws -> Data { ... }
    func setEntry(_ data: Data, forKey key: String) throws { ... }
    func deleteEntry(forKey key: String) throws { ... }

    func deleteAllEntries() throws {
        // Delete all entries from your custom storage
    }
}
```
</details>

**Impact:** If you have a custom `CredentialsStorage` implementation and use `clearAll()`, you must implement the `deleteAllEntries()` method. If you don't use `clearAll()`, no changes are needed — the default implementation will only trigger an assertion if called. The default `SimpleKeychain`-based storage already provides this implementation.

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
- `.credentialsManagerError` - The credentials manager failed to store or clear credentials. The underlying error can be accessed via the `cause` property.

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

**`UserInfo` → `UserProfile`**

The `UserInfo` struct has been renamed to `UserProfile`. The `userInfo(withAccessToken:)` method name on the Authentication client is unchanged, as it maps to the OIDC `/userinfo` endpoint.

**`expiresIn` → `expiresAt`**

The `expiresIn` property on `Credentials`, `APICredentials`, and `SSOCredentials` has been renamed to `expiresAt`. The JSON key (`expires_in`) and Keychain storage key are unchanged.

**`Telemetry` → `Auth0ClientInfo`**

The `Telemetry` struct has been renamed to `Auth0ClientInfo`, and the `telemetry` property on `Trackable` conforming types has been renamed to `auth0ClientInfo`.

### Request to Requestable

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

> [!NOTE] When using Web Auth (PKCE flow), ID token validation is performed automatically. You do not need to call `validateClaims()` yourself.

> [!NOTE] This applies to the `Authentication` client only. If `validateClaims()` is enabled but the response does not contain an ID token, the request fails with `AuthenticationError` wrapping `IDTokenDecodingError.missingIDToken` rather than silently succeeding. In Web Auth, a missing ID token results in `WebAuthError.idTokenValidationFailed` instead.

<details>
  <summary>Affected methods (now return <code>any TokenRequestable</code> instead of <code>Request</code>)</summary>

- `Authentication.login(email:code:audience:scope:)`
- `Authentication.login(phoneNumber:code:audience:scope:)`
- `Authentication.login(usernameOrEmail:password:realmOrConnection:audience:scope:)`
- `Authentication.loginDefaultDirectory(withUsername:password:audience:scope:)`
- `Authentication.login(appleAuthorizationCode:fullName:profile:audience:scope:)`
- `Authentication.login(facebookSessionAccessToken:profile:audience:scope:)`
- `Authentication.login(passkey:challenge:connection:audience:scope:)` (both `LoginPasskey` and `SignupPasskey` variants)
- `Authentication.codeExchange(withCode:codeVerifier:redirectURI:)`
- `Authentication.ssoExchange(withRefreshToken:)`
- `Authentication.renew(withRefreshToken:audience:scope:)`
- `MFAClient.verify(oobCode:bindingCode:mfaToken:)`
- `MFAClient.verify(otp:mfaToken:)`
- `MFAClient.verify(recoveryCode:mfaToken:)`

</details>

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

---

## Getting Help

If you encounter issues during migration:

- [GitHub Issues](https://github.com/auth0/Auth0.swift/issues) - Report bugs or ask questions
- [Auth0 Community](https://community.auth0.com/) - Community support

### MFA methods on Authentication protocol

**Change:** The following deprecated MFA methods have been removed from the `Authentication` protocol:

- `login(withOTP:mfaToken:)`
- `login(withOOBCode:mfaToken:bindingCode:)`
- `login(withRecoveryCode:mfaToken:)`
- `multifactorChallenge(mfaToken:types:authenticatorId:)`

**Impact:** Any code that calls these methods on an `Authentication` client will no longer compile.

**Migration:** Use the dedicated `MFAClient` protocol instead, accessible via `Auth0.mfa()`:

| Before (v2) | After (v3) |
| --- | --- |
| `Auth0.authentication().login(withOTP: otp, mfaToken: mfaToken)` | `Auth0.mfa().verify(otp: otp, mfaToken: mfaToken)` |
| `Auth0.authentication().login(withOOBCode: code, mfaToken: mfaToken, bindingCode: bindingCode)` | `Auth0.mfa().verify(oobCode: code, bindingCode: bindingCode, mfaToken: mfaToken)` |
| `Auth0.authentication().login(withRecoveryCode: code, mfaToken: mfaToken)` | `Auth0.mfa().verify(recoveryCode: code, mfaToken: mfaToken)` |
| `Auth0.authentication().multifactorChallenge(mfaToken: mfaToken, types: types, authenticatorId: id)` | `Auth0.mfa().challenge(with: id, mfaToken: mfaToken)` |

See the [MFA API section](EXAMPLES.md#mfa-api-ios--macos--tvos--watchos--visionos) in EXAMPLES.md for full usage details.

---
[Go up ⤴](#table-of-contents)
