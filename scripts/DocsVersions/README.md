# DocsVersions

A small, dependency-free Swift tool that folds a freshly-built [DocC](https://www.swift.org/documentation/docc/)
static site into a **versioned** GitHub Pages layout, with a runtime version-switcher
dropdown injected into every page.

It is the DocC counterpart to TypeDoc's
[`@shipgirl/typedoc-plugin-versions`](https://github.com/shipgirl/typedoc-plugin-versions):
DocC renders its navigation as a client-side Vue app, so there is no per-page HTML
to rewrite at build time. Instead, a tiny script (`version-selector.js`) is injected
before `</head>` and adds the dropdown at runtime by reading a shared `versions.json`.

The package has **zero external dependencies** (its own minimal SemVer) so it can be
lifted out of this repo and published as a standalone tool for the community.

## What it does

Given a fresh DocC build and a gh-pages working copy, it:

1. Reads the version from `Auth0/Version.swift` (or `--version`).
2. Replaces `v<version>/` with the new build (always overwrites the current version).
3. Injects `<script defer src="/<base-path>/version-selector.js"></script>` into every page.
4. Applies a **keep-two-major-lines** retention policy (mirrors react-native-auth0):
   - stable release → keep the two most recent stable majors (highest patch each);
   - prerelease → keep the prerelease plus the latest earlier stable major.
5. Writes the site root: `versions.json` (+ `stable` pointer), `version-selector.js`,
   an `index.html` redirect to the newest version, and `.nojekyll`.

## Usage

```bash
swift run --package-path scripts/DocsVersions DocsVersions \
  --site-root <gh-pages working copy> \
  --new-build <freshly transformed DocC static site> \
  [--version X.Y.Z] \
  [--version-file Auth0/Version.swift] \
  [--base-path Auth0.swift]
```

The DocC build that feeds `--new-build` must be transformed with a version-scoped
hosting base path so each folder is self-contained:

```bash
docc process-archive transform-for-static-hosting <archive> \
  --hosting-base-path Auth0.swift/v<version> \
  --output-path <new-build dir>
```

In this repo, `bundle exec fastlane build_docs` produces that build into `docs_build/`.

## Tests

```bash
swift test --package-path scripts/DocsVersions
```

Covers SemVer parsing/ordering (incl. prerelease precedence) and the retention policy.
