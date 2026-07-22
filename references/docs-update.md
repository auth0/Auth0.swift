# Docs Update Rules

## Tracked Docs

| File | Covers | Exists |
|------|--------|--------|
| `README.md` | Installation (SPM/CocoaPods/Carthage), quick-start, configuration (`Auth0.plist`), callback URL setup, Web Auth setup | ✅ present |
| `EXAMPLES.md` | Web Auth, Credentials Manager, Authentication API, MFA, My Account API (EA), Logging, Advanced Features — runnable code samples per feature | ✅ present |

## When You Change Code, Update These Docs

| When this changes | Update |
|-------------------|--------|
| Public API added to `Authentication`, `WebAuth`, `CredentialsManager`, `MFAClient`, or `MyAccount` protocols | `EXAMPLES.md` — add a usage sample under the relevant section |
| Public API removed or renamed in any protocol | `README.md` + `EXAMPLES.md` — remove or update every reference to the old symbol |
| Installation requirements change (new platform minimum, new Xcode requirement, new package version) | `README.md` — Requirements and Installation sections; also update the version pin in all three package manager snippets |
| `Auth0.plist` keys or SDK initialisation options change | `README.md` — Configure the SDK section |
| Callback / logout URL setup changes | `README.md` — Configure Web Auth section |
| New integration pattern supported (e.g., new grant type, new provider, new EA feature) | `EXAMPLES.md` — add a new section with a runnable example |
| DPoP behaviour changes (key generation, nonce handling, logout) | `EXAMPLES.md` — DPoP section |
| My Account API methods added, removed, or promoted from EA to GA | `EXAMPLES.md` — My Account API section; update EA callout if promoted |
| Biometric auth options or `CredentialsManager` init signature changes | `EXAMPLES.md` — Credentials Manager / Biometric authentication section |

> When you touch code that maps to a doc above, update that doc **in the same PR** — do not defer.
