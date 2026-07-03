# Dependencies — Auth0.swift

## Core (shipped with the SDK)

| Package | Version | Purpose |
|---------|---------|---------|
| SimpleKeychain | 1.3.0 (exact) | Keychain access abstraction for secure token storage |
| JWTDecode.swift | 3.3.0 (exact) | ID token parsing |

Declared in `Package.swift` and `Auth0.podspec`. Versions are **pinned exact** in SPM — bumping affects all three package managers (SPM, CocoaPods, Carthage), so it is an Ask-First change.

## Test only

| Package | Version | Purpose |
|---------|---------|---------|
| Quick | ≥ 7.0.0 (up-to-next-major) | BDD test framework |
| Nimble | ≥ 13.0.0 (up-to-next-major) | Assertion matchers |

## Development tools (Ruby, via Bundler / `Gemfile`)

| Tool | Purpose |
|------|---------|
| Carthage | Builds `.xcframework`s for Xcode-project development |
| SwiftLint | Static analysis (installed via Homebrew in CI) |
| Slather | Coverage report generation |
| Fastlane | Release automation + DocC generation |
| CocoaPods | `pod lib lint`, `pod trunk push` |
