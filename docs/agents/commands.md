# Commands Reference — Auth0.swift

Full command list. The root `CLAUDE.md` keeps only the core three (`swift test`, `swiftlint lint`, `swiftlint --fix`).

## Test

```bash
# All tests via SPM (fastest local option)
swift test

# Per-scheme via xcodebuild (matches CI)
xcodebuild test -project Auth0.xcodeproj -scheme Auth0.iOS   -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -project Auth0.xcodeproj -scheme Auth0.macOS  -destination 'platform=macOS'
xcodebuild test -project Auth0.xcodeproj -scheme Auth0.tvOS   -destination 'platform=tvOS Simulator,name=Apple TV'

# Single spec
xcodebuild test -project Auth0.xcodeproj -scheme Auth0.iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Auth0Tests/CredentialsManagerSpec

# watchOS has no test target (Quick has no watchOS build) — CI only builds it.
# Must target the real device destination, not the simulator: watchOS device
# archs (armv7k/arm64_32) use a 32-bit Int, the simulator uses 64-bit like macOS,
# so simulator-only builds miss 32-bit-only overflows (e.g. GH issue #1240).
xcodebuild build -project Auth0.xcodeproj -scheme Auth0.watchOS -destination 'generic/platform=watchOS'
```

## Lint

```bash
swiftlint lint                                    # local
swiftlint lint --reporter github-actions-logging  # CI reporter
swiftlint --fix                                   # auto-fix
bundle exec pod lib lint --allow-warnings --fail-fast   # validate CocoaPods spec
```

## Dependencies / build

```bash
# Carthage (required before Xcode-project development — the project uses built .xcframeworks)
carthage bootstrap --use-xcframeworks
carthage bootstrap --platform iOS --use-xcframeworks --no-use-binaries --cache-builds

# Resolve SPM deps (CI, offline-pinned)
xcodebuild -resolvePackageDependencies -skipPackageUpdates -onlyUsePackageVersionsFromResolvedFile
```

## Coverage

```bash
# iOS only, after tests (CI uploads to Codecov)
bundle exec slather coverage -x --scheme Auth0.iOS Auth0.xcodeproj
```

## Docs

```bash
bundle exec fastlane build_docs   # build the versioned DocC site
```
