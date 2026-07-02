# AI Agent Guidelines for Auth0.swift

This document provides context and guidelines for AI coding assistants working with the Auth0.swift codebase.

## Project Overview

**Auth0.swift** is the official Auth0 SDK for Apple platforms — providing authentication, authorization, and credential management for iOS, macOS, tvOS, watchOS, and visionOS apps.

- **Language:** Swift 5.0+ (Package.swift uses Swift 6.0 tools)
- **Tech Stack:** Apple platforms, Xcode 16.x, SPM + CocoaPods + Carthage, URLSession, Combine, CryptoKit
- **Package Manager:** Swift Package Manager (primary), CocoaPods, Carthage (development deps)
- **Minimum Platform Versions:** iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0

---

## Commands

> Copy-paste ready. These are the exact commands used in CI.

```bash
# Run all tests via Swift Package Manager (fastest local option)
swift test

# Run tests for a specific Xcode scheme (used in CI)
xcodebuild test -project Auth0.xcodeproj -scheme Auth0.iOS -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -project Auth0.xcodeproj -scheme Auth0.macOS -destination 'platform=macOS'
xcodebuild test -project Auth0.xcodeproj -scheme Auth0.tvOS -destination 'platform=tvOS Simulator,name=Apple TV'

# Lint (must pass before merging)
swiftlint lint --reporter github-actions-logging

# Lint with auto-fix
swiftlint lint --fix

# Bootstrap Carthage dependencies (required for Xcode project development)
carthage bootstrap --use-xcframeworks

# Bootstrap Carthage for a specific platform
carthage bootstrap --platform iOS --use-xcframeworks --no-use-binaries --cache-builds

# Coverage report (iOS only, run after tests)
bundle exec slather coverage -x --scheme Auth0.iOS Auth0.xcodeproj

# Validate CocoaPods spec
bundle exec pod lib lint --allow-warnings --fail-fast

# Resolve SPM dependencies
xcodebuild -resolvePackageDependencies -skipPackageUpdates -onlyUsePackageVersionsFromResolvedFile

# Generate API documentation (DocC via Fastlane)
bundle exec fastlane build_docs
```

---

## Testing

- **Framework:** Quick 7.0+ (BDD) + Nimble 13.0+ (assertions)
- **Test Location:** `Auth0Tests/`
- **Coverage Tool:** Slather + Codecov (iOS scheme only in CI)
- **Coverage Threshold:** Tracked via Codecov; target >80%

### Running Tests

```bash
# Run all unit tests via SPM (quickest)
swift test

# Run a specific test spec via xcodebuild
xcodebuild test -project Auth0.xcodeproj \
  -scheme Auth0.iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Auth0Tests/CredentialsManagerSpec
```

### Testing Conventions

- Every spec file is a `QuickSpec` subclass named `<Subject>Spec` (e.g., `CredentialsManagerSpec`).
- Behavior is organized with nested `describe` / `context` / `it` blocks.
- `it` descriptions use present tense, declarative style: `"should return credentials when valid"`.
- `beforeEach` / `afterEach` handle setup and teardown.
- `StubURLProtocol` intercepts all network calls — never make real network requests in tests.
- `NetworkStub.clearStubs()` must be called in every `afterEach`.
- Test constants use `UPPER_CAMEL_CASE` names (e.g., `AccessToken`, `ClientId`, `Domain`).
- Combine publishers are tested with Nimble async matchers or `waitUntil`.
- Platform-specific tests are gated with `#if WEB_AUTH_PLATFORM` and `#if PASSKEYS_PLATFORM`.
- Test both presence **and absence** of request parameters: when a param is optional, add a case asserting it is **not** sent when `nil`, not just that it is present when set. `hasAllOf` / `hasAtLeast` only check for presence, so absence needs its own assertion.

### Mocking & Test Utilities

- Network: `StubURLProtocol` + `NetworkStub` (register/clear stubs per test)
- Keychain: `SimpleKeychain` is used directly; tests clean up Keychain state in `afterEach`
- Platform guards: tests mirror the same `#if WEB_AUTH_PLATFORM` / `#if PASSKEYS_PLATFORM` flags as source

---

## Project Structure

```
Auth0.swift/
├── Auth0/                        # Library source (85 Swift files)
│   ├── Auth0.swift               # Public result type aliases & top-level factory functions
│   ├── Authentication.swift      # Authentication protocol (OAuth2 / OIDC)
│   ├── Auth0Authentication.swift # Concrete Authentication implementation
│   ├── AuthenticationError.swift # Authentication API error type
│   ├── CredentialsManager.swift  # Thread-safe Keychain credential storage & renewal
│   ├── CredentialsManagerError.swift
│   ├── Credentials.swift         # User credentials model
│   ├── WebAuth.swift             # Web Auth protocol (Universal Login)
│   ├── Auth0WebAuth.swift        # Concrete WebAuth implementation
│   ├── WebAuthError.swift
│   ├── Version.swift             # Single source of truth for SDK version string
│   ├── DPoP/                     # DPoP (Demonstration of Proof-of-Possession) support
│   │   ├── DPoP.swift
│   │   └── DPoPError.swift
│   ├── MFA/                      # Multi-factor authentication
│   │   ├── MFAClient.swift
│   │   ├── Auth0MFAClient.swift
│   │   └── MFAErrors.swift
│   ├── MyAccount/                # My Account API
│   │   ├── MyAccount.swift
│   │   ├── MyAccountError.swift
│   │   └── AuthenticationMethods/
│   └── Utils/                    # Internal utilities
├── Auth0Tests/                   # Test specs (56 files, mirrors Auth0/ structure)
│   ├── Auth0Spec.swift
│   ├── AuthenticationSpec.swift
│   ├── CredentialsManagerSpec.swift
│   ├── DPoP/
│   ├── MFA/
│   └── MyAccount/
├── Documentation.docc/           # DocC documentation bundle
├── App/                          # Demo application
├── fastlane/                     # Release automation (Fastfile)
├── .github/
│   ├── workflows/
│   │   ├── main.yml              # CI: tests, lint, pod-lint
│   │   ├── claude-code-review.yml
│   │   ├── sca_scan.yml
│   │   └── rl-scanner.yml
│   └── actions/
│       ├── setup/                # Composite: Ruby + CocoaPods + Xcode setup
│       └── test/                 # Composite: Carthage bootstrap + xcodebuild
├── Auth0.xcodeproj
├── Auth0.podspec
├── Package.swift
├── Cartfile / Cartfile.resolved
└── CHANGELOG.md
```

### Key Files

| File | Purpose |
|------|---------|
| `Auth0/Auth0.swift` | Entry point: result type aliases and factory functions (`Auth0.authentication()`, `Auth0.webAuth()`, etc.) |
| `Auth0/Version.swift` | Version string — single source of truth; bump here for every release |
| `Auth0/CredentialsManager.swift` | Thread-safe credential storage, renewal, biometric auth |
| `Auth0/Authentication.swift` | Full OAuth2/OIDC Authentication protocol definition |
| `Auth0/WebAuth.swift` | Universal Login protocol (iOS/macOS/visionOS only, `WEB_AUTH_PLATFORM`) |
| `Auth0.podspec` | CocoaPods spec; `s.version` must match `Version.swift` |
| `Package.swift` | SPM manifest; lists all targets, platforms, and dependencies |
| `.swiftlint.yml` | SwiftLint config — lints only the `Auth0/` source directory |
| `CHANGELOG.md` | Keep a Changelog format; updated for every release |

---

## Code Style

### Linter & Formatter

- **Linter:** SwiftLint — Config: `.swiftlint.yml`
  - Opt-in rules: `empty_count`
  - Disabled rules: `void_function_in_ternary`, `large_tuple`, `blanket_disable_command`
  - Line length: 500 (not the primary style enforcement)
  - Type body length: 300 warning / 400 error
- **Formatter:** No auto-formatter enforced; 4-space indentation, no tabs

### Naming Conventions

- Types (classes, structs, protocols, enums): `PascalCase` — e.g., `CredentialsManager`, `AuthenticationError`, `WebAuthError`
- Functions and properties: `camelCase` — e.g., `accessToken`, `renewCredentials`, `enableBiometrics`
- Constants in test files: `UpperCamelCase` (private let at file scope) — e.g., `AccessToken`, `ClientId`, `Domain`
- Protocol-backed implementations are prefixed with `Auth0`: `Auth0Authentication`, `Auth0WebAuth`, `Auth0MFAClient`
- Error types end in `Error`: `AuthenticationError`, `WebAuthError`, `CredentialsManagerError`

### Conditional Compilation

```swift
// Only iOS, macOS, macCatalyst, visionOS — never use #if os(iOS) for SDK-level WebAuth guards
#if WEB_AUTH_PLATFORM
// Only iOS, macOS, macCatalyst, visionOS (Passkeys)
#if PASSKEYS_PLATFORM
```

### Code Examples

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

### Patterns Used in This Project

- **Protocol + concrete implementation:** Every public API is a protocol (`Authentication`, `WebAuth`, `MFAClient`); the concrete type is package-internal (`Auth0Authentication`, `Auth0WebAuth`).
- **Builder pattern:** `WebAuth` uses a fluent builder — `webAuth.scope("openid").connection("google-oauth2").start()`.
- **Result type aliases:** Each subsystem has a typed result alias — `AuthenticationResult<T>`, `WebAuthResult<T>`, `CredentialsManagerResult<T>`, `MyAccountResult<T>`.
- **Dual API (callback + async/await):** Every public method exposes both a completion handler variant and a Swift concurrency (`async throws`) variant.
- **Sendable / thread safety:** `CredentialsManager` is `Sendable`; concurrent methods use `NSLock` internally. Document thread-safety limits in DocC comments.
- **Explicit `Sendable` on public models:** Conform public model/response types to `Sendable` explicitly (matching `Credentials`, `PasskeySignupChallenge`) rather than relying on module-boundary inference. Never reach for `@unchecked Sendable` — if a stored dictionary is the blocker, type it as `[String: any Sendable]` instead of `[String: Any]`.
- **API parameter ordering:** The primary noun being acted on comes first; supporting inputs follow. Match the existing passkey APIs — e.g. `login(otp:challenge:audience:scope:)`, mirroring `login(passkey:challenge:...)`.
- **DocC disambiguation suffixes:** Don't add symbol disambiguation hashes to DocC links preemptively. Add them only when a symbol genuinely has multiple overloads that require disambiguation.

---

## Git Workflow

### Branch Naming

No enforced convention; use descriptive names: `feature/dpop-support`, `fix/credentials-renewal-race`, `chore/bump-dependencies`.

### Commit Messages

Free-form with conventional-style prefixes used in practice:

```
feat: add flexible grant type support
fix: correct memory leak in ASUserAgent
chore: deprecate Management API client
docs: update Native to Web feature docs for GA release
```

### Pull Requests

Use `.github/PULL_REQUEST_TEMPLATE.md`:

- All new/changed/fixed functionality must be covered by tests.
- All new/changed public API must have DocC comments.
- Required CI checks: unit tests on iOS + macOS + tvOS, SwiftLint, pod lib lint, Swift package tests.
- Sections: **Changes** (types/methods added/deleted/deprecated/changed), **References** (GitHub issues, community posts), **Testing** (how reviewers can verify).

### Changelog

Keep a Changelog format. Update `CHANGELOG.md` for every user-facing change under the correct heading: **Added**, **Changed**, **Deprecated**, **Fixed**, **Security**, **Removed**.

---

## Boundaries

### ✅ Always Do

- Write or update tests in `Auth0Tests/` for every new or changed behavior.
- Add DocC comments (`/// ...`) to all `public` types, methods, and properties.
- Update `CHANGELOG.md` for every user-facing addition, change, fix, deprecation, or security update.
- Gate WebAuth and Passkeys code with `#if WEB_AUTH_PLATFORM` / `#if PASSKEYS_PLATFORM`.
- Expose both a completion-handler API and an `async throws` API for any new public method.
- Keep `Auth0/Version.swift` and `Auth0.podspec` `s.version` in sync.
- Follow the existing error hierarchy — use or extend typed error structs (`AuthenticationError`, `WebAuthError`, etc.).
- Run `swiftlint lint` and resolve all warnings before submitting.
- Use `StubURLProtocol` / `NetworkStub` for all network interactions in tests.
- Update `README.md` and `EXAMPLES.md` in the same PR when changing the public API, configuration options, or supported integration patterns.

### ⚠️ Ask First

- Adding new external dependencies (SPM packages or CocoaPods pods).
- Modifying public API signatures — breaking changes require a major version bump.
- Adding new minimum platform versions or dropping support for existing ones.
- Changes to `.github/workflows/` CI configuration.
- Modifying security-sensitive code: DPoP key generation, PKCE, token storage, biometric auth.
- Deprecating or removing any public API.
- Changes to `Package.swift` target structure (adding targets, changing paths, new compilation conditions).
- Adding a parameter to an existing public protocol requirement — provide a default implementation via a protocol extension so existing custom conformers keep compiling, and call out the change in the changelog.

### 🚫 Never Do

- Commit secrets, API keys, tokens, or `.plist` files containing real credentials.
- Log `accessToken`, `refreshToken`, `idToken`, or any sensitive user data — not in source, not in tests.
- Disable PKCE — it is always enabled for Authorization Code flows.
- Bypass or weaken DPoP proof generation.
- Force-unwrap optionals in library source code.
- Use `#if os(iOS)` / `#if os(macOS)` for guards that belong under `WEB_AUTH_PLATFORM` / `PASSKEYS_PLATFORM`.
- Modify files under `Carthage/`, `Pods/`, `.build/`, or `docs/` (generated artifacts) by hand.
- Remove or skip failing tests instead of fixing them.
- Break backward API compatibility without a major version bump and explicit team approval.
- Write `public` types or methods without DocC documentation comments.
- Reference internal-only information (feature-flag names, internal tooling, or unreleased infrastructure) in public docs such as `README.md` and `EXAMPLES.md`.

---

## Security Considerations

1. **PKCE:** Always enabled for Authorization Code flows — never provide an option to disable it.
2. **Token Storage:** Keychain via `SimpleKeychain` — never `UserDefaults`, `NSCache`, or in-memory-only storage for sensitive tokens.
3. **Token Logging:** Never log `accessToken`, `refreshToken`, `idToken`, or `recoveryCode` — not even in debug builds.
4. **DPoP:** Supported — keys generated in the Secure Enclave where available. Do not silently downgrade to software keys.
5. **Certificate Pinning:** Not built-in; can be configured via a custom `URLSession` passed at init.
6. **Biometric Auth:** Optional gate on `CredentialsManager.credentials()` via `LocalAuthentication` — never store biometric data.

---

## Dependencies

### Core (shipped with SDK)

| Package | Version | Purpose |
|---------|---------|---------|
| `SimpleKeychain` | 1.3.0 | Keychain access abstraction |
| `JWTDecode.swift` | 3.3.0 | ID token parsing and validation |

### Test Only

| Package | Version | Purpose |
|---------|---------|---------|
| `Quick` | 7.0.0+ | BDD test framework |
| `Nimble` | 13.0.0+ | Assertion matchers |

### Development Tools

| Tool | Purpose |
|------|---------|
| Carthage | Resolves test/dev dependencies for the Xcode project |
| SwiftLint | Static analysis |
| Slather | Coverage report generation |
| Bundler | Manages Ruby tools (CocoaPods, Fastlane, Slather) |
| Fastlane | Release automation and DocC generation |

---

## Release Process

1. Bump version in **`Auth0/Version.swift`** — single source of truth.
2. Update **`Auth0.podspec`** `s.version` to match.
3. Update **`CHANGELOG.md`** — add release heading with date and full change list.
4. Open a PR, get review, merge to `master`.
5. Tag the release: `git tag <version> && git push --tags`.
6. Run Fastlane release lane: `bundle exec fastlane release` — tags, pushes podspec to CocoaPods trunk.
7. The `rl-scanner` CI job scans the release artifact automatically on release PRs.

---

## Common Pitfalls

1. **Missing conditional compilation flag:** `WebAuth` and Passkeys types only exist on `WEB_AUTH_PLATFORM`. Forgetting `#if WEB_AUTH_PLATFORM` causes tvOS/watchOS build failures.
2. **Carthage vs SPM for development:** The Xcode project uses Carthage-built `.xcframework`s. Run `carthage bootstrap --use-xcframeworks` before opening the project in Xcode; SPM is only used for `swift test` in CI.
3. **Thread safety of CredentialsManager:** Only `credentials()`, `apiCredentials()`, `ssoCredentials()`, and `renew()` are thread-safe. Accessing non-thread-safe properties (e.g., `bioAuth`) from concurrent contexts requires external synchronization.
4. **Swift 6 concurrency:** `Package.swift` uses Swift language mode v5 but `swift-tools-version:6.0`. Adding new `Sendable` conformances requires understanding the existing lock-based concurrency model — check `@unchecked Sendable` usages first.
5. **Nimble async matchers:** Use `await expect(value).to(...)` — not `expect(value).toEventually(...)` with a synchronous expectation, which produces flaky tests under Swift concurrency.

---

## External References

- [README](https://github.com/auth0/Auth0.swift/blob/master/README.md)
- [API Documentation (DocC)](https://auth0.github.io/Auth0.swift/documentation/auth0/)
- [Auth0 iOS Quickstart](https://auth0.com/docs/quickstart/native/ios-swift)
- [Auth0 Developer Docs](https://auth0.com/docs)
- [Changelog](https://github.com/auth0/Auth0.swift/blob/master/CHANGELOG.md)
- [Contributing Guide](https://github.com/auth0/Auth0.swift/blob/master/CONTRIBUTING.md)
- [SimpleKeychain](https://github.com/auth0/SimpleKeychain)
- [JWTDecode.swift](https://github.com/auth0/JWTDecode.swift)

---

## Docs Update Rules

> Treat documentation as a first-class deliverable. A PR that adds or changes public API, configuration, or integration patterns is **not complete** until the relevant docs are updated in the same PR.

### Tracked Docs

| File | Covers | Status |
|------|--------|--------|
| `README.md` | Installation (SPM/CocoaPods/Carthage), quick-start, configuration (`Auth0.plist`), callback URL setup, Web Auth setup | ✅ current |
| `EXAMPLES.md` | Web Auth, Credentials Manager, Authentication API, MFA, My Account API, Management API, DPoP, Logging — runnable code samples per feature | ✅ current |

### When You Change Code, Update These Docs

| When this changes | Update |
|-------------------|--------|
| Public API added to `Authentication`, `WebAuth`, `CredentialsManager`, `MFAClient`, or `MyAccount` protocols | `EXAMPLES.md` — add a usage sample under the relevant section |
| Public API removed or renamed in any protocol | `README.md` + `EXAMPLES.md` — remove or update every reference to the old symbol |
| Installation requirements change (new platform minimum, new Xcode requirement, new package version) | `README.md` — Requirements and Installation sections; also update the `~> X.Y` version pin in all three package manager snippets |
| `Auth0.plist` keys or SDK initialisation options change | `README.md` — Configure the SDK section |
| Callback / logout URL setup changes | `README.md` — Configure Web Auth section |
| New integration pattern supported (e.g., new grant type, new provider, new EA feature) | `EXAMPLES.md` — add a new section with a runnable example |
| DPoP behaviour changes (key generation, nonce handling, logout) | `EXAMPLES.md` — DPoP section |
| My Account API methods added, removed, or promoted from EA to GA | `EXAMPLES.md` — My Account API section; update EA callout if promoted |
| Biometric auth options or `CredentialsManager` init signature changes | `EXAMPLES.md` — Credentials Manager / Biometric authentication section |

### Drift Status (as of last scan)

Both tracked docs are current against the public API surface at v2.22.0. No stale symbols detected.

- `README.md` — installation snippets reference `~> 2.22` ✅, platform requirements match `Package.swift` ✅
- `EXAMPLES.md` — `updateAuthenticationMethod` (added 2.21.0) ✅, `getAuthenticationMethods(type:)` filter ✅, DPoP on My Account API ✅

> If you are adding a feature and the drift status above is out of date, run a manual check: search `EXAMPLES.md` for every new public symbol and confirm a usage example exists.
