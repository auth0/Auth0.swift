# Testing

- **Framework:** Quick 7.0+ (BDD) + Nimble 13.0+ (assertions)
- **Test Location:** `Auth0Tests/`
- **Coverage Tool:** Slather + Codecov (iOS scheme only in CI)
- **Coverage Threshold:** Tracked via Codecov (`codecov.yml`): project threshold 2%, patch threshold 50%

## Running Tests

```bash
# Run all unit tests via SPM (quickest)
swift test

# Run a specific test spec via xcodebuild
xcodebuild test -project Auth0.xcodeproj \
  -scheme Auth0.iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Auth0Tests/CredentialsManagerSpec
```

## Testing Conventions

- Every spec file is a `QuickSpec` subclass named `<Subject>Spec` (e.g., `CredentialsManagerSpec`).
- Behavior is organized with nested `describe` / `context` / `it` blocks.
- `it` descriptions use present tense, declarative style: `"should return credentials when valid"`.
- `beforeEach` / `afterEach` handle setup and teardown.
- `StubURLProtocol` intercepts all network calls — never make real network requests in tests.
- `NetworkStub.clearStubs()` must be called in every `afterEach`.
- Test constants use `UPPER_CAMEL_CASE` names (e.g., `AccessToken`, `ClientId`, `Domain`) declared as file-scope `private let`.
- Combine publishers are tested with Nimble async matchers or `waitUntil`.
- Platform-specific tests are gated with `#if WEB_AUTH_PLATFORM` and `#if PASSKEYS_PLATFORM`.

## Mocking & Test Utilities

- Network: `StubURLProtocol` + `NetworkStub` (register/clear stubs per test)
- Keychain: `SimpleKeychain` is used directly; tests clean up Keychain state in `afterEach`
- Platform guards: tests mirror the same `#if WEB_AUTH_PLATFORM` / `#if PASSKEYS_PLATFORM` flags as source

## Nimble Async Matchers

Use `await expect(value).to(...)` — not `expect(value).toEventually(...)` with a synchronous expectation, which produces flaky tests under Swift concurrency.
