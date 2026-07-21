# Git Workflow

## Branch Naming

No enforced convention; use descriptive names: `feature/dpop-support`, `fix/credentials-renewal-race`, `chore/bump-dependencies`.

## Commit Messages

Free-form with conventional-style prefixes used in practice:

```
feat: add flexible grant type support
fix: correct memory leak in ASUserAgent
chore: deprecate Management API client
docs: update Native to Web feature docs for GA release
```

## Pull Requests

Use `.github/PULL_REQUEST_TEMPLATE.md`:

- All new/changed/fixed functionality must be covered by tests.
- All new/changed public API must have DocC comments.
- Required CI checks: unit tests on iOS + macOS + tvOS, SwiftLint, pod lib lint, Swift package tests.
- Sections: **Changes** (types/methods added/deleted/deprecated/changed), **References** (GitHub issues, community posts), **Testing** (how reviewers can verify).

## Changelog

Keep a Changelog format. Update `CHANGELOG.md` for every user-facing change under the correct heading: **Added**, **Changed**, **Deprecated**, **Fixed**, **Security**, **Removed**.
