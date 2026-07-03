# Common Pitfalls — Auth0.swift

1. **Missing conditional-compilation flag.** `WebAuth` and Passkeys types only exist under `WEB_AUTH_PLATFORM` / `PASSKEYS_PLATFORM` (iOS/macOS/macCatalyst/visionOS). Forgetting the `#if` guard breaks the tvOS/watchOS builds. Never substitute `#if os(iOS)` for these flags. ~30 source files use them.

2. **Carthage vs SPM for development.** The Xcode project builds against Carthage `.xcframework`s. Run `carthage bootstrap --use-xcframeworks` before opening the project. SPM (`swift test`) is used for the package tests in CI; both must pass.

3. **`CredentialsManager` thread-safety is scoped.** Only `credentials()`, `apiCredentials()`, `ssoCredentials()`, and `renew()` are thread-safe (guarded by an internal lock). Accessing other members (e.g. `bioAuth`) concurrently needs external synchronization.

4. **Swift 6 tools, v5 language mode.** `Package.swift` is `swift-tools-version:6.0` but compiles in language mode v5. Adding `Sendable` conformances requires understanding the existing lock-based concurrency model — check existing `@unchecked Sendable` usages before adding new ones.

5. **Nimble async matchers.** Prefer `await expect(value).to(...)` over `expect(value).toEventually(...)` on a synchronous expectation — the latter is flaky under Swift concurrency.

6. **Three-package-manager parity.** A dependency or platform-minimum change must be reflected in `Package.swift`, `Auth0.podspec`, and the Carthage setup together, plus the version pins in `README.md`.
