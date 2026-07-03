# AI Agent Guidelines for Auth0.swift

This document provides context and guidelines for AI coding assistants working with the Auth0.swift codebase.

## Your Role

You are a Swift SDK engineer working on Auth0.swift, the Auth0 authentication SDK for Apple platforms (iOS, macOS, tvOS, watchOS, visionOS). You write protocol-oriented, testable Swift that ships across three package managers (SPM, CocoaPods, Carthage), and you treat backward compatibility and secure token handling as non-negotiable.

---

## Project Overview

**Auth0.swift** is the official Auth0 SDK for Apple platforms — authentication, authorization, and credential management.

- **Language:** Swift 5.0+ (`Package.swift` uses `swift-tools-version:6.0`, language mode v5)
- **Distribution:** Swift Package Manager (primary), CocoaPods (`Auth0.podspec`), Carthage (`Cartfile`)
- **Min platforms:** iOS 14, macOS 11, tvOS 14, watchOS 7, visionOS 1
- **Core deps:** SimpleKeychain 1.3.0, JWTDecode 3.3.0 · **Test deps:** Quick, Nimble

---

## Commands

```bash
# Run all tests (fastest local option)
swift test

# Lint (must pass before merging)
swiftlint lint

# Auto-fix lint issues
swiftlint --fix
```

See [docs/commands.md](docs/commands.md) for the full command reference (per-scheme xcodebuild tests, Carthage bootstrap, pod lib lint, coverage, DocC). **Read that file only when you need to run, build, test, or release.**

---

## Testing

- **Framework:** Quick (BDD `describe`/`context`/`it`) + Nimble (matchers)
- **Location:** `Auth0Tests/`, specs named `<Subject>Spec.swift` (`QuickSpec` subclasses)
- **Coverage:** Slather → Codecov (iOS scheme only, in CI); target >80%
- All tests are **unit tests** — no live tenant or credentials required.

### Conventions (must-follow — prevents flaky/networked tests)
- **Never make real network requests.** Use `StubURLProtocol` + `NetworkStub`; call `NetworkStub.clearStubs()` in every `afterEach`.
- Clean up Keychain state in `afterEach` (SimpleKeychain is used directly).
- Test Combine/async with Nimble async matchers — prefer `await expect(...)` over `toEventually(...)` on a sync expectation (the latter is flaky under Swift concurrency).
- Mirror source platform gates in tests: `#if WEB_AUTH_PLATFORM` / `#if PASSKEYS_PLATFORM`.

See [docs/commands.md](docs/commands.md) for the single-spec xcodebuild invocation.

---

## Project Structure

```
Auth0/           # SDK source (~85 Swift files)
  ├─ Auth0.swift            # public entry point — authentication()/mfa()/users()/webAuth() factories
  ├─ Authentication.swift, WebAuth.swift, Users.swift  # public protocols
  ├─ Auth0Authentication.swift, Auth0WebAuth.swift     # concrete (package-internal) impls
  ├─ *Error.swift           # typed errors conforming to Auth0Error
  ├─ CredentialsManager.swift  # thread-safe Keychain storage & renewal
  ├─ Telemetry.swift        # Auth0-Client telemetry header
  ├─ Version.swift          # single source of truth for the version string
  ├─ DPoP/, MFA/, MyAccount/ # feature areas
Auth0Tests/      # Quick/Nimble specs (mirror Auth0/)
Documentation.docc/  # DocC catalog     App/  # demo app
scripts/DocsVersions/  # versioned-docs tooling     fastlane/  # release + build_docs
```

Key files: `Auth0/Auth0.swift` (entry point), `Auth0/Version.swift` (bump per release, keep in sync with `Auth0.podspec` `s.version`), `.swiftlint.yml` (lints `Auth0/` only).

---

## Code Style

- **Linter:** SwiftLint (`.swiftlint.yml`; `line_length` 500, `type_body_length` 300/400, `identifier_name`/`type_name` min 3). Lints `Auth0/` only. No auto-formatter; 4-space indent.
- **Naming:** `UpperCamelCase` types, `lowerCamelCase` members; concrete impls prefixed `Auth0` (`Auth0Authentication`); error types end in `Error`.
- **Conditional compilation:** WebAuth/Passkeys code is gated with `#if WEB_AUTH_PLATFORM` / `#if PASSKEYS_PLATFORM` — **never** `#if os(iOS)` for these guards.

Dominant patterns: public **protocol** + package-internal concrete type; fluent **builder** (`webAuth.scope(...).connection(...).start()`); typed result aliases (`AuthenticationResult<T>`); **dual API** — every public method has both a completion-handler and an `async throws` variant. See `Auth0/Authentication.swift` and `Auth0/WebAuth.swift`.

---

## Git Workflow

- **Branches:** `release/vX.Y.Z` for releases; descriptive names otherwise (`feature/…`, `fix/…`)
- **Commits:** conventional-style prefixes (`feat:`, `fix:`, `chore:`, `docs:`)
- **PRs:** satisfy `.github/PULL_REQUEST_TEMPLATE.md` — tests for all changes, DocC comments for all public API. Required checks: unit tests (iOS/macOS/tvOS), SwiftLint, pod lib lint, SPM tests.
- **Changelog:** Keep a Changelog format in `CHANGELOG.md`, every user-facing change.

---

## Boundaries

### ✅ Always Do
- Run `swift test` and `swiftlint lint` before committing
- Add Quick/Nimble specs for new behavior; add DocC comments to all `public` API
- Expose both a completion-handler and an `async throws` API for new public methods
- Keep `Auth0/Version.swift` and `Auth0.podspec` `s.version` in sync
- Update `README.md` and `EXAMPLES.md` in the same PR when changing the public API, configuration options, or supported integration patterns
- Update `V2_MIGRATION_GUIDE.md` in the same PR when making a breaking change
- When adding a new feature/public API, wire the `Auth0-Client` telemetry header following the pattern in `Auth0/Telemetry.swift`

### ⚠️ Ask First
- Adding/bumping dependencies (affects SPM, CocoaPods, and Carthage)
- Modifying public API signatures on `Authentication`/`WebAuth`/`Users`/`CredentialsManager` (breaking → major bump)
- Raising a minimum platform version (`Package.swift` / `Auth0.podspec`)
- Changes to `.github/workflows/` or release tooling (`fastlane/`)
- Modifying security-sensitive code: DPoP key generation, PKCE, token storage, biometric auth

### 🚫 Never Do
- Commit secrets, API keys, tokens, or `.plist` files with real credentials
- Log `accessToken` / `refreshToken` / `idToken` / `recoveryCode` — not even in debug or tests
- Disable PKCE or weaken DPoP proof generation
- Force-unwrap optionals in library source
- Edit generated/vendored dirs by hand (`Carthage/`, `Pods/`, `.build/`, `DerivedData/`, `docs/`)
- Remove or skip failing specs instead of fixing the cause
- Break backward compatibility without a major bump, explicit approval, and a `V2_MIGRATION_GUIDE.md` entry

---

## Security Considerations

- **PKCE:** always enabled for Authorization Code flows — never expose an option to disable it.
- **Token storage:** Keychain via SimpleKeychain only — never `UserDefaults`/`NSCache`/in-memory for tokens.
- **Token logging:** never log tokens or `Credentials` contents.
- **DPoP:** keys generated in the Secure Enclave where available (`Auth0/DPoP/`); do not silently downgrade to software keys.
- **ID tokens:** validated (signature + claims) in `IDTokenValidator*.swift` — do not bypass validation.

---

## Dependencies

See [docs/dependencies.md](docs/dependencies.md) for the full core/test/dev dependency list with versions. **Read only when auditing or changing dependencies.**

---

## Release Process

Version source of truth: `Auth0/Version.swift`, kept in sync with `Auth0.podspec` `s.version`. Release runs via `bundle exec fastlane release` (tags, `pod lib lint`, `pod trunk push` with retry) driven by `.github/workflows/release.yml`; DocC site published by `docs.yml`.

See [docs/releasing.md](docs/releasing.md) for the full runbook. **Read only when cutting a release.**

---

## Common Pitfalls

See [docs/pitfalls.md](docs/pitfalls.md) for platform gotchas (conditional-compilation flags, Carthage bootstrap before Xcode work, `CredentialsManager` thread-safety limits, Swift 6 tools + v5 language mode, Nimble async matchers). **Read when debugging build/platform/concurrency issues.**

---

## Docs Update Rules

> A PR that changes public API, configuration, or supported patterns is **not complete** until the relevant docs are updated in the same PR.

### Tracked Docs

| Doc | Status | Covers |
|-----|--------|--------|
| `README.md` | ✅ current | Install (SPM/CocoaPods/Carthage), quick-start, config, Web Auth, support policy |
| `EXAMPLES.md` | ✅ current | Web Auth, Credentials Manager, Authentication/MFA/My Account/Management APIs, DPoP, logging |
| `V2_MIGRATION_GUIDE.md` | ✅ current | v1 → v2 breaking changes |

### When You Change Code, Update These Docs

| When this changes | Update |
|-------------------|--------|
| Public API on `Authentication`/`WebAuth`/`Users`/`CredentialsManager`/`MFAClient`/`MyAccount` | `README.md` (usage), `EXAMPLES.md` (affected samples) |
| Public API removed or renamed | `README.md` + `EXAMPLES.md` — update every reference to the old symbol |
| Installation requirements (platform min, Xcode, package version) | `README.md` (Requirements/Installation; bump version pins in all three package managers) |
| `Auth0.plist` keys / SDK init options | `README.md` (Configure the SDK) |
| New integration pattern (grant type, provider, EA feature) | `EXAMPLES.md` (new section) |
| Any breaking change | `V2_MIGRATION_GUIDE.md` |

### Drift Status

All tracked docs are current.

---

## External References

- [README](https://github.com/auth0/Auth0.swift/blob/master/README.md) · [EXAMPLES](https://github.com/auth0/Auth0.swift/blob/master/EXAMPLES.md) · [V2_MIGRATION_GUIDE](https://github.com/auth0/Auth0.swift/blob/master/V2_MIGRATION_GUIDE.md)
- [API Documentation (DocC)](https://auth0.github.io/Auth0.swift/documentation/auth0/) · [iOS Quickstart](https://auth0.com/docs/quickstart/native/ios-swift)
- [SimpleKeychain](https://github.com/auth0/SimpleKeychain) · [JWTDecode.swift](https://github.com/auth0/JWTDecode.swift)
