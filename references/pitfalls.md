# Common Pitfalls

1. **Missing conditional compilation flag:** `WebAuth` and Passkeys types only exist on `WEB_AUTH_PLATFORM`. Forgetting `#if WEB_AUTH_PLATFORM` causes tvOS/watchOS build failures.
2. **Carthage vs SPM for development:** The Xcode project uses Carthage-built `.xcframework`s. Run `carthage bootstrap --use-xcframeworks` before opening the project in Xcode; SPM is only used for `swift test` in CI.
3. **Thread safety of CredentialsManager:** Only `credentials()`, `apiCredentials()`, `ssoCredentials()`, and `renew()` are thread-safe. Accessing non-thread-safe properties (e.g., `bioAuth`) from concurrent contexts requires external synchronization.
4. **Swift 6 concurrency:** `Package.swift` uses `.swiftLanguageMode(.v6)` for the library target but `.swiftLanguageMode(.v5)` for the test target. Adding new `Sendable` conformances requires understanding the existing lock-based concurrency model — check `@unchecked Sendable` usages first.
5. **Nimble async matchers:** Use `await expect(value).to(...)` — not `expect(value).toEventually(...)` with a synchronous expectation, which produces flaky tests under Swift concurrency.
