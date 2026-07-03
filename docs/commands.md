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
