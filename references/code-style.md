# Code Style

## Linter & Formatter

- **Linter:** SwiftLint — Config: `.swiftlint.yml`
  - Opt-in rules: `empty_count`
  - Disabled rules: `void_function_in_ternary`, `large_tuple`, `blanket_disable_command`
  - Line length: 500 (not the primary style enforcement)
  - Type body length: 300 warning / 400 error
- **Formatter:** No auto-formatter enforced; 4-space indentation, no tabs

## Naming Conventions

- Types (classes, structs, protocols, enums): `PascalCase` — e.g., `CredentialsManager`, `AuthenticationError`, `WebAuthError`
- Functions and properties: `camelCase` — e.g., `accessToken`, `renewCredentials`, `enableBiometrics`
- Constants in test files: `UpperCamelCase` (private let at file scope) — e.g., `AccessToken`, `ClientId`, `Domain`
- Protocol-backed implementations are prefixed with `Auth0`: `Auth0Authentication`, `Auth0WebAuth`, `Auth0MFAClient`
- Error types end in `Error`: `AuthenticationError`, `WebAuthError`, `CredentialsManagerError`

## Conditional Compilation

```swift
// Only iOS, macOS, macCatalyst, visionOS — never use #if os(iOS) for SDK-level WebAuth guards
#if WEB_AUTH_PLATFORM
// Only iOS, macOS, macCatalyst, visionOS (Passkeys)
#if PASSKEYS_PLATFORM
```

## Code Examples

**✅ Good — typed Result, dual async/callback API, no force-unwrap:**

```swift
public func credentials(withScope scope: String? = nil,
                        minTTL: Int = 0,
                        parameters: [String: Any] = [:],
                        headers: [String: String] = [:]) async throws -> Credentials {
    return try await withCheckedThrowingContinuation { continuation in
        self.credentials(withScope: scope, minTTL: minTTL, parameters: parameters, headers: headers) {
            continuation.resume(with: $0)
        }
    }
}
```

**❌ Bad — stringly-typed error, force-unwrap, untyped completion:**

```swift
func getCredentials(completion: @escaping (Any?, Error?) -> Void) {
    let creds = storage.getCredentials()!  // force-unwrap
    completion(creds, nil)
}
```

## Patterns Used in This Project

- **Protocol + concrete implementation:** Every public API is a protocol (`Authentication`, `WebAuth`, `MFAClient`); the concrete type is package-internal (`Auth0Authentication`, `Auth0WebAuth`).
- **Builder pattern:** `WebAuth` uses a fluent builder — `webAuth.scope("openid").connection("google-oauth2").start()`.
- **Result type aliases:** Each subsystem has a typed result alias — `AuthenticationResult<T>`, `WebAuthResult<T>`, `CredentialsManagerResult<T>`, `MyAccountResult<T>`.
- **Dual API (callback + async/await):** Every public method exposes both a completion handler variant and a Swift concurrency (`async throws`) variant.
- **Sendable / thread safety:** `CredentialsManager` is `Sendable`; concurrent methods use `NSLock` internally. Document thread-safety limits in DocC comments.
