# AI Agent Guidelines for Auth0.swift

This document provides context and guidelines for AI coding assistants working with the Auth0.swift codebase.

## Your Role

You are a Swift SDK engineer maintaining Auth0.swift, the official Auth0 authentication SDK for Apple platforms (iOS, macOS, tvOS, watchOS, visionOS). You write small, well-tested, dual-API (callback + `async throws`) code that follows the existing protocol/concrete-implementation split.

---

## Working Principles

Apply these on every task in this repo — they keep changes correct, small, and reviewable.

- **Think before coding.** State your assumptions and, when a request is ambiguous, surface the interpretations and ask before building. Recommend a simpler approach when you see one. A clarifying question up front beats a wrong implementation.
- **Simplicity first.** Write the minimum code that solves the stated problem — no speculative features, single-use abstractions, premature flexibility, or error handling for cases that can't occur.
- **Surgical changes.** Touch only what the request requires. Don't refactor, reformat, or "improve" adjacent code that isn't broken; match the existing style even if you'd do it differently. Every changed line should trace directly to the request. Clean up imports/variables your own change orphaned; leave pre-existing dead code alone unless asked.
- **Goal-driven execution.** Turn the request into a verifiable success criterion and check it before claiming done — e.g. "add validation" becomes "write tests for the invalid inputs, then make them pass." Don't report success you haven't verified.

---

## Project Overview

**Auth0.swift** is the official Auth0 SDK for Apple platforms — providing authentication, authorization, and credential management for iOS, macOS, tvOS, watchOS, and visionOS apps.

- **Language:** Swift 5.0+ (Package.swift uses Swift 6.0 tools, `.swiftLanguageMode(.v6)` for the library target)
- **Tech Stack:** Apple platforms, Xcode 16.1, SPM + CocoaPods + Carthage, URLSession, Combine, CryptoKit
- **Package Manager:** Swift Package Manager (primary), CocoaPods, Carthage (development deps)
- **Minimum Platform Version:** iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0
- **Dependencies:** SimpleKeychain 1.3.0, JWTDecode.swift 4.0.0 · test: Quick 7.0+, Nimble 13.0+ — see `Package.swift` for the authoritative list

---

## Project Structure

```
Auth0.swift/
├── Auth0/                        # Library source (121 Swift files)
│   ├── Auth0.swift               # Public result type aliases & top-level factory functions
│   ├── Authentication.swift      # Authentication protocol (OAuth2 / OIDC)
│   ├── Auth0Authentication.swift # Concrete Authentication implementation
│   ├── CredentialsManager.swift  # Thread-safe Keychain credential storage & renewal
│   ├── Credentials.swift         # User credentials model
│   ├── WebAuth.swift              # Web Auth protocol (Universal Login)
│   ├── Auth0WebAuth.swift         # Concrete WebAuth implementation
│   ├── Auth0ClientInfo.swift      # Auth0-Client telemetry header generation
│   ├── Version.swift               # Single source of truth for SDK version string
│   ├── DPoP/                      # DPoP (Demonstration of Proof-of-Possession) support
│   ├── MFA/                       # Multi-factor authentication
│   ├── MyAccount/                 # My Account API (EA)
│   └── ...                        # OAuth2, JWT/JWKS, passkeys, keychain utils, etc.
├── Auth0Tests/                    # Test specs (65 files, mirrors Auth0/ structure)
│   ├── DPoP/
│   ├── MFA/
│   └── MyAccount/
├── Documentation.docc/             # DocC documentation bundle
├── App/                            # Demo application (uses Auth0.plist config)
├── fastlane/                       # Release automation (Fastfile)
├── .github/
│   ├── workflows/main.yml          # CI: tests, lint, pod-lint
│   └── actions/{setup,test}/       # Composite: Ruby+CocoaPods+Xcode setup, Carthage+xcodebuild test
├── Auth0.xcodeproj
├── Auth0.podspec
├── Package.swift
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
| `Auth0/Auth0ClientInfo.swift` | `Auth0-Client` telemetry header generation and opt-out |
| `Auth0.podspec` | CocoaPods spec; `s.version` must match `Version.swift` |
| `Package.swift` | SPM manifest; lists all targets, platforms, and dependencies |
| `.swiftlint.yml` | SwiftLint config — lints only the `Auth0/` source directory |
| `CHANGELOG.md` | Keep a Changelog format; updated for every release |

---

## Boundaries

### ✅ Always Do

- Write or update tests in `Auth0Tests/` for every new or changed behavior.
- Add DocC comments (`/// ...`) to all `public` types, methods, and properties.
- Update `CHANGELOG.md` for every user-facing addition, change, fix, deprecation, or security update.
- Gate WebAuth and Passkeys code with `#if WEB_AUTH_PLATFORM` / `#if PASSKEYS_PLATFORM`.
- Expose both a completion-handler API and an `async throws` API for any new public method.
- Keep `Auth0/Version.swift` and `Auth0.podspec` `s.version` in sync — this is the version source of truth.
- Follow the existing error hierarchy — use or extend typed error structs (`AuthenticationError`, `WebAuthError`, etc.).
- Run `swiftlint lint` and resolve all warnings before submitting.
- Use `StubURLProtocol` / `NetworkStub` for all network interactions in tests.
- Update `README.md` and `EXAMPLES.md` in the same PR when changing the public API, configuration options, or supported integration patterns.
- When adding a **new outbound request path to Auth0**, route it through the existing `Auth0/Auth0ClientInfo.swift` mechanism so it carries the `Auth0-Client` header — don't hand-roll a separate client — and preserve the `tracking(enabled:)` opt-out.

### ⚠️ Ask First

- **Any breaking change — always ask first.** Never make a breaking change on your own initiative; stop and ask the maintainer before writing it.
- Adding new external dependencies (SPM packages or CocoaPods pods).
- Modifying public API signatures.
- Adding new minimum platform versions or dropping support for existing ones.
- Changes to `.github/workflows/` CI configuration.
- Modifying security-sensitive code: DPoP key generation, PKCE, token storage, biometric auth.
- Deprecating or removing any public API.

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

---

## Security Considerations

1. **PKCE:** Always enabled for Authorization Code flows (`Auth0/OAuth2Grant.swift`) — never provide an option to disable it.
2. **Token Storage:** Keychain via `SimpleKeychain` — never `UserDefaults`, `NSCache`, or in-memory-only storage for sensitive tokens.
3. **Token Logging:** Never log `accessToken`, `refreshToken`, `idToken`, or `recoveryCode` — not even in debug builds.
4. **DPoP:** Supported (`Auth0/DPoP/`) — keys generated in the Secure Enclave where available (`SecureEnclaveKeyStore.swift`), falling back to a Keychain-backed store. Do not silently downgrade to software keys without the existing fallback path.
5. **Certificate Pinning:** Not built-in; can be configured via a custom `URLSession` passed at init.
6. **Biometric Auth:** Optional gate on `CredentialsManager.credentials()` via `LocalAuthentication` (`Auth0/BioAuthentication.swift`) — never store biometric data.

---

> The sections below are reference — each keeps a one-line anchor here and offloads detail to `references/*.md`.

## Commands

```bash
swift test                    # Run all tests via SPM (fastest local option)
swiftlint lint --reporter github-actions-logging   # Lint (must pass before merging)
```

See [references/commands.md](references/commands.md) for the full command reference (xcodebuild per-scheme, Carthage bootstrap, coverage, pod lint, DocC generation). Read only when you need to build, test, or lint beyond the two commands above.

## Testing

- **Framework:** Quick 7.0+ (BDD) + Nimble 13.0+ (assertions)
- **Test Location:** `Auth0Tests/`
- The default `swift test` suite is unit-only — `StubURLProtocol` intercepts all network calls, no credentials required.

See [references/testing.md](references/testing.md) for spec conventions, mocking utilities, coverage tooling, and how to run a single spec via `xcodebuild`. Read when writing or modifying tests.

## Code Style

- **Naming:** Types `PascalCase`, functions/properties `camelCase`, error types end in `Error`, protocol-backed implementations prefixed `Auth0` (e.g. `Auth0Authentication`).
- **CI-enforced (SwiftLint, `.swiftlint.yml`):** line length 500, type body length 300 warning / 400 error, `empty_count` opt-in rule — a SwiftLint failure blocks CI.

See [references/code-style.md](references/code-style.md) for good/bad code examples and the dominant patterns (protocol + concrete implementation, builder, dual callback/async API). Read before writing new public API.

## Git Workflow

- **Commits:** Free-form with conventional-style prefixes (`feat:`, `fix:`, `chore:`, `docs:`).
- **PRs:** Must follow `.github/PULL_REQUEST_TEMPLATE.md` — new/changed functionality covered by tests, documentation added.

See [references/git-workflow.md](references/git-workflow.md) for branch naming, the full PR checklist, and CHANGELOG format. Read before opening a PR.

## Common Pitfalls

See [references/pitfalls.md](references/pitfalls.md) for the full list (missing `WEB_AUTH_PLATFORM` guards, Carthage vs SPM for dev, `CredentialsManager` thread-safety limits, Swift 6 concurrency, Nimble async matchers). Read when debugging a build failure or flaky test.

## Docs Update Rules

> Treat documentation as a first-class deliverable. A PR that adds or changes public API, configuration, or integration patterns is **not complete** until the relevant docs are updated in the same PR — see the Always Do rule above.

See [references/docs-update.md](references/docs-update.md) for the tracked-docs inventory (`README.md`, `EXAMPLES.md`) and the full code-to-docs mapping table. Read before closing out a PR that touches public API.
