# Commands

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

# Bootstrap Carthage for a specific platform (used in CI's test action)
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

## CI Structure

- `.github/workflows/main.yml` runs on every PR: `test` (matrix over iOS/macOS/tvOS via `Auth0.xcodeproj` + Xcode 16.1), `test-package` (`swift test`), `pod-lint`, and `swiftlint`.
- `.github/actions/setup/action.yml` — composite action: Ruby + CocoaPods + Xcode setup.
- `.github/actions/test/action.yml` — composite action: SPM cache restore, Carthage bootstrap per platform, `xcodebuild` test run with coverage enabled.
