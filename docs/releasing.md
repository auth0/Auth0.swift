# Release Runbook — Auth0.swift

1. Bump the version in **`Auth0/Version.swift`** — the single source of truth.
2. Update **`Auth0.podspec`** `s.version` to match (they must stay in sync).
3. Update **`CHANGELOG.md`** — add a release heading (Keep a Changelog format: Added / Changed / Deprecated / Fixed / Security / Removed).
4. Add breaking-change upgrade steps to **`V2_MIGRATION_GUIDE.md`** if applicable.
5. Open a `release/vX.Y.Z` PR, get review, merge.
6. Run the release lane:
   ```bash
   bundle exec fastlane release
   ```
   This tags the release, runs `pod lib lint`, and `pod trunk push`es to CocoaPods (with retry/backoff, since `pod trunk info` can lag after a successful publish).
7. `.github/workflows/release.yml` creates the GitHub Release (via `softprops/action-gh-release`) and calls `docs.yml` to publish the versioned DocC site to `gh-pages`.
8. The `rl-scanner` job scans the release artifact.

Notes:
- The GitHub Release is created by the workflow, **not** the fastlane plugin (the Actions `GITHUB_TOKEN` is rejected by the Releases API under Basic auth).
- DocC deploys are serialized via a `gh-pages-deploy` concurrency group.
