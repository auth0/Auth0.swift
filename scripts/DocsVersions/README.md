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
4. Applies a **keep-two-major-lines** retention policy:
   - **latest major** → its latest release; if that major has a stable, its betas
     are dropped (stable wins), otherwise its latest prerelease is kept (so a live
     next-major preview like `3.0.0-beta.2` survives while a lower-major stable ships);
   - **previous major** → its latest stable release.

   The current release is always among the newest, so it is always kept. When the
   current release is a prerelease, the latest stable below it is additionally
   retained even if it shares the current major (e.g. `2.24.0-beta.1` keeps `2.23.0`),
   so the stable users rely on stays live during a preview.
5. For a stable release (`--new-build-root` provided), mirrors that version at the
   site root so the default docs serve from a **version-less URL** (the historical
   canonical URL). Prereleases omit this and leave the root serving the last stable.
6. Writes the site root: `versions.json` (+ `stable` pointer), `version-selector.js`,
   `.nojekyll`, and always rewrites `index.html` (overwriting DocC's own loader stub).
   When stable content owns the root it redirects to `documentation/auth0/`; otherwise
   (no stable published yet) it redirects into the newest version's `/v<version>/` folder.

## Root-mirror model

The default stable version is served **directly at the site root** (e.g.
`/Auth0.swift/documentation/auth0/`), while every version — including the stable one —
is also addressable under its `/v<version>/` folder. DocC bakes **absolute** asset
paths at transform time, so the same archive is transformed twice for a stable release:
once with the version base path (`Auth0.swift/v<version>` → `--new-build`) and once with
the bare base path (`Auth0.swift` → `--new-build-root`).

The root is a **disposable mirror** of the current stable, rebuilt on each stable
release; the `/v<version>/` folders are the source of truth. When folding in a stable
release, the tool clears the previous stable's root DocC content (preserving every
`v*/` alias plus the shared `versions.json`, `version-selector.js`, and `.nojekyll`),
then lays down the new stable's root copy. Prereleases never take over the root, so the
last stable keeps serving the default docs even while a beta is published under its alias.

## Usage

```bash
swift run --package-path scripts/DocsVersions DocsVersions \
  --site-root <gh-pages working copy> \
  --new-build <freshly transformed DocC static site> \
  [--new-build-root <root-base-path transform, stable releases only>] \
  [--version X.Y.Z] \
  [--version-file Auth0/Version.swift] \
  [--base-path Auth0.swift]
```

The DocC build that feeds `--new-build` must be transformed with a version-scoped
hosting base path so each folder is self-contained. A stable release additionally
feeds `--new-build-root` with a second transform of the same archive built with the
bare base path, which is served at the site root:

```bash
# Versioned alias (always)
docc process-archive transform-for-static-hosting <archive> \
  --hosting-base-path Auth0.swift/v<version> \
  --output-path <new-build dir>

# Root mirror (stable releases only) → pass as --new-build-root
docc process-archive transform-for-static-hosting <archive> \
  --hosting-base-path Auth0.swift \
  --output-path <new-build-root dir>
```

In this repo, `bundle exec fastlane build_docs` produces the versioned build into
`docs_build/` and, for a stable release, the root build into `docs_build_root/`.

## Tests

```bash
swift test --package-path scripts/DocsVersions
```

Covers SemVer parsing/ordering (incl. prerelease precedence) and the retention policy.
