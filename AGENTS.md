# AI Agent Guidelines for Auth0.swift

This document provides context and guidelines for AI coding assistants working with the Auth0.swift codebase.

## Project Overview

**Auth0.swift** is an idiomatic Swift SDK for integrating Auth0 authentication and authorization into Apple platform applications.

- **Language:** Swift 6.0 (swift-tools-version: 6.0, language mode: Swift 5)
- **Tech Stack:** iOS 14+, macOS 11+, tvOS 14+, watchOS 7+, visionOS 1+, SPM, CocoaPods, Carthage
- **Package Manager:** Swift Package Manager (primary), CocoaPods, Carthage
- **Minimum Platform Version:** iOS 14, macOS 11, tvOS 14, watchOS 7, visionOS 1

---

## Commands

> Copy-paste ready. These are the exact commands used in CI.

```bash
# Build (SPM)
swift build

# Run all tests (SPM)
swift test

# Run tests for a specific platform (xcodebuild — matches CI)
xcodebuild test -scheme Auth0.iOS -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild test -scheme Auth0.macOS -destination 'platform=macOS'
xcodebuild test -scheme Auth0.tvOS -destination 'platform=tvOS Simulator,name=Apple TV'

# Lint
swiftlint lint --reporter github-actions-logging

# Coverage (iOS only, requires slather gem)
bundle exec slather coverage -x --scheme Auth0.iOS Auth0.xcodeproj

# Lint podspec
bundle exec pod lib lint --allow-warnings --fail-fast

# Generate documentation (DocC)
swift package generate-documentation

# Resolve SPM dependencies
swift package resolve

# Bootstrap Carthage dependencies (for Xcode development)
carthage bootstrap --use-xcframeworks

# Release (tags + publishes to CocoaPods)
bundle exec fastlane release
```

---

## Testing

- **Framework:** Quick 7+ + Nimble 13+ (BDD), XCTest (underlying runner)
- **Test Location:** `Auth0Tests/`
- **Coverage Tool:** Slather + Codecov
- **Coverage Threshold:** Tracked via Codecov (no hard gate, upload on iOS run)

### Running Tests

```bash
# Run all tests via SPM
swift test

# Run a specific test file (SPM — uses --filter with test class name)
swift test --filter CredentialsManagerSpec

# Run via xcodebuild (iOS)
xcodebuild test -scheme Auth0.iOS -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing Conventions

- Test files are named `*Spec.swift` and use Quick's `describe/context/it` BDD DSL
- Use `beforeEach` / `afterEach` for setup and teardown
- Use `expect(...).to(...)` Nimble matchers (never `XCTAssert`)
- Test all three concurrency patterns: async/await, Combine, and completion handlers
- Cover three scenarios per feature: success, API error, network failure
- Use `waitUntil` or `expect(...).toEventually(...)` for async tests with a 2s timeout

### Mocking & Test Utilities

- Protocol-based mocking: implement the protocol (e.g., `Authentication`, `CredentialsStorage`) in test-only types
- `StubURLProtocol` + `NetworkStub` for HTTP-level mocking — register/unregister in `beforeEach`/`afterEach`
- `URLProtocol.registerClass(StubURLProtocol.self)` pattern used consistently across all network specs

---

## Project Structure

```
Auth0.swift/
├── Auth0/                          # Main SDK source
│   ├── Auth0.swift                 # Public entry point (Auth0.webAuth(), Auth0.authentication())
│   ├── Authentication.swift        # Authentication protocol
│   ├── Auth0Authentication.swift   # Authentication API client
│   ├── WebAuth/                    # Universal Login via ASWebAuthenticationSession
│   ├── CredentialsManager.swift    # Secure storage & automatic token refresh
│   ├── Credentials.swift           # Token model
│   ├── DPoP/                       # DPoP (Demonstrating Proof of Possession) support
│   ├── MFA/                        # Multi-factor authentication flows
│   ├── Networking/                 # Request/response layer
│   ├── Auth0Error.swift            # Base error type
│   ├── AuthenticationError.swift   # Authentication API errors
│   ├── CredentialsManagerError.swift
│   └── Version.swift               # SDK version constant
├── Auth0Tests/                     # Unit tests (Quick/Nimble specs)
├── Package.swift                   # SPM manifest
├── Auth0.podspec                   # CocoaPods spec (kept in sync with Package.swift)
├── Cartfile                        # Carthage dependencies
├── .swiftlint.yml                  # SwiftLint configuration
├── fastlane/                       # Release automation
├── .github/workflows/              # CI: main.yml, claude-code-review.yml, sca_scan.yml
├── Documentation.docc              # DocC documentation
├── CHANGELOG.md                    # Keep a Changelog format
├── CONTRIBUTING.md                 # Dev setup and contribution guide
└── README.md                       # Quickstart
```

### Key Files

| File | Purpose |
|------|---------|
| `Auth0/Auth0.swift` | Public factory methods: `Auth0.webAuth()`, `Auth0.authentication()` |
| `Auth0/CredentialsManager.swift` | Token storage, expiry checks, automatic refresh |
| `Auth0/Version.swift` | SDK version string — update on every release |
| `Auth0.podspec` | CocoaPods spec — must stay in sync with `Package.swift` |
| `.swiftlint.yml` | Lint rules — `line_length: 500`, `type_body_length: 300/400` |
| `fastlane/Fastfile` | `release` lane: tag + CocoaPods publish |

---

## Code Style

### Linter & Formatter

- **Linter:** SwiftLint — Config: `.swiftlint.yml`
- Lints only the `Auth0/` directory (excludes `Carthage/`, `Pods/`)
- Opt-in rule: `empty_count`; disabled: `void_function_in_ternary`, `large_tuple`, `blanket_disable_command`
- `line_length: 500`, `type_body_length: 300` (warning) / `400` (error)

### Naming Conventions

- Types: `PascalCase` (e.g., `CredentialsManager`, `WebAuthError`)
- Functions/properties: `camelCase` (e.g., `accessToken`, `renewAuth`)
- Constants: `PascalCase` private file-level constants in test files (e.g., `AccessToken`, `RefreshToken`)
- Files: match primary type name (e.g., `CredentialsManager.swift`)
- Test files: `*Spec.swift` suffix (e.g., `CredentialsManagerSpec.swift`)
- Min identifier length: 3 characters (SwiftLint enforced)

### API Design — Tri-brid Concurrency Model

Every public async API **must** expose three variants:

✅ Good — all three concurrency styles present:

```swift
// Async/Await (primary)
func credentials() async throws -> Credentials

// Combine
func credentials() -> AnyPublisher<Credentials, CredentialsManagerError>

// Completion handler
func credentials(callback: @escaping (Result<Credentials, CredentialsManagerError>) -> Void)
```

❌ Bad — only one style, breaks existing integrations:

```swift
// Missing Combine and completion handler variants
func credentials() async throws -> Credentials
```

### Patterns

- **Protocol-Oriented**: API contracts defined as protocols (`Authentication`, `WebAuth`, `CredentialsStorage`) — enables protocol-based mocking in tests
- **Builder pattern**: WebAuth flow uses chained method calls (`.scope()`, `.connection()`, `.audience()`)
- **Result type**: All completion handlers use `Result<T, Auth0Error>`
- **@MainActor callbacks**: All public completion-handler APIs dispatch callbacks on the main actor

---

## Git Workflow

### Branch Naming

- Feature branches: `feat/<description>` or `feature/<description>`
- Fix branches: `fix/<description>`
- Release branches: `release/<version>` (e.g., `release/2.18.0`) — triggers RL Scanner on merge

### Commit Messages

Conventional Commits format:

```
feat: add automatic retry for credential renewal
fix: correct rl-wrapper flag from --suppress_output to --suppress-output
chore: update SDK version to 2.18.0
docs: update migration guide for v3
```

### Pull Requests

- CI runs: tests on iOS/macOS/tvOS (Xcode 16.1), SwiftLint, pod lib lint
- Coverage uploaded to Codecov (iOS only)
- Use PR template; reference Jira ticket or GitHub issue

### Changelog

Keep a Changelog format with categories: `Added`, `Changed`, `Deprecated`, `Fixed`, `Security`. Example:

```markdown
## [2.18.0](https://github.com/auth0/Auth0.swift/tree/2.18.0) (2026-03-05)
**Added**
- feat: make Auth0APIError.isRetryable public
```

---

## Boundaries

### ✅ Always Do

- Run `swift test` before committing
- Follow SwiftLint rules — run `swiftlint lint` locally before pushing
- Add `///` documentation to all new public APIs
- Add unit tests covering success, API error, and network failure
- Update `CHANGELOG.md` for every user-facing change
- Implement all three concurrency variants (async/await, Combine, completion handler) for new async public APIs
- Dispatch completion-handler callbacks on `@MainActor`
- Use typed errors: `AuthenticationError`, `WebAuthError`, `CredentialsManagerError`
- Update `Auth0/Version.swift` and `Auth0.podspec` together on releases

### ⚠️ Ask First

- Adding new dependencies to `Package.swift` / `Auth0.podspec`
- Modifying public API signatures (source-breaking changes)
- Changing minimum platform versions
- Changes to `.github/workflows/` CI configuration
- Modifying security-related code (PKCE, DPoP, token storage, state validation)
- Updating `Auth0.podspec` — must stay in sync with `Package.swift`

### 🚫 Never Do

- Commit secrets, API keys, or tokens
- Log access tokens, refresh tokens, or ID tokens — anywhere
- Disable PKCE for WebAuth flows
- Store tokens in `UserDefaults` — always use `CredentialsManager` + `SimpleKeychain`
- Modify `Carthage/`, `Pods/`, or build output directories
- Remove or skip failing tests without fixing them
- Break public API backward compatibility without explicit approval and a migration guide
- Modify auto-generated files (DocC output, SPM-resolved lock files) by hand

---

## Security Considerations

1. **PKCE**: Enabled by default for all WebAuth flows — never disable
2. **Token Storage**: `SimpleKeychain` (Keychain) only — never `UserDefaults` or plain files
3. **Token Logging**: Never log access tokens, refresh tokens, or ID tokens
4. **DPoP**: Supported — see `Auth0/DPoP/` directory
5. **State Validation**: Random state strings used to prevent CSRF in web flows
6. **Certificate Pinning**: Configurable via `URLSession` for high-security deployments

---

## Dependencies

### Core

- **SimpleKeychain** `1.3.0` — Keychain access (iOS/macOS/tvOS/watchOS)
- **JWTDecode.swift** `4.0.0` — JWT decoding for claims and expiry

### Test

- **Quick** `7.0+` — BDD test framework
- **Nimble** `13.0+` — Matcher library for Quick

### Dev / Release

- **fastlane** — Release automation (tagging, CocoaPods publish)
- **cocoapods** — podspec linting and publishing
- **slather** — Coverage report conversion (Xcode → Cobertura XML for Codecov)
- **Carthage** — Dependency manager for Xcode project development setup

---

## Release Process

1. Update version in `Auth0/Version.swift` (e.g., `let version = "2.19.0"`)
2. Update `Auth0.podspec` `s.version` to match
3. Update `CHANGELOG.md` with release date and entries
4. Open PR on a `release/<version>` branch — CI runs full test suite
5. Merge PR → `master`
6. Run `bundle exec fastlane release` to tag and push to CocoaPods
7. RL Security Scanner runs automatically on merged release PRs

---

## Common Pitfalls

- **Callback URL mismatch**: The URL scheme in `Auth0 Dashboard` must match `CFBundleURLTypes` in `Info.plist` (format: `com.example.app://YOUR_DOMAIN/ios/com.example.app/callback`)
- **Missing `@MainActor`**: UI updates from SDK callbacks must be dispatched on the main actor — the SDK does this internally, but calling code must not assume a background thread
- **Retain cycles in closures**: Use `[weak self]` captures in closures within `CredentialsManager` to avoid leaks
- **Single podspec/Package.swift sync**: Forgetting to update `Auth0.podspec` after changing `Package.swift` will break `pod lib lint` in CI
- **Platform-conditional APIs**: `WebAuth` is only available on `iOS`, `macOS`, `macCatalyst`, `visionOS` — guard with `#if WEB_AUTH_PLATFORM` (defined in `Package.swift`)
- **`Auth0.plist` vs `Info.plist`**: The SDK reads `ClientId`/`Domain` from `Auth0.plist` in test targets; production apps typically use `Auth0.plist` or pass values programmatically

---

## External References

- [README](https://github.com/auth0/Auth0.swift/blob/master/README.md)
- [EXAMPLES.md](https://github.com/auth0/Auth0.swift/blob/master/EXAMPLES.md)
- [API Docs (DocC)](https://auth0.github.io/Auth0.swift/documentation/auth0/)
- [Auth0 Docs — Swift Quickstart](https://auth0.com/docs/quickstart/native/ios-swift)
- [CONTRIBUTING.md](https://github.com/auth0/Auth0.swift/blob/master/CONTRIBUTING.md)
- [SimpleKeychain](https://github.com/auth0/SimpleKeychain)
- [JWTDecode.swift](https://github.com/auth0/JWTDecode.swift)
