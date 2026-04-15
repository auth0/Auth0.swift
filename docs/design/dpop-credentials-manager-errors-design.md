# Design Doc: DPoP CredentialsManager Error Cases

**Source PR:** [auth0/Auth0.Android#949](https://github.com/auth0/Auth0.Android/pull/949)
**Target SDK:** auth0.swift
**Branch:** `feat/dpop-credentials-manager-errors`

---

## Overview

Auth0.Android PR #949 adds three new DPoP-specific error codes to `CredentialsManagerException`,
plus validation logic that guards credential renewal operations when stored credentials are DPoP-bound.
This doc describes the equivalent implementation for auth0.swift.

---

## Source Analysis

The Android PR introduces three error scenarios that can occur when credentials are DPoP-bound (i.e.,
have `tokenType == "DPoP"` or have a stored DPoP key thumbprint) but the current runtime state does
not match what was saved:

| Error Code           | Trigger                                                                      | Side Effect              |
|----------------------|------------------------------------------------------------------------------|--------------------------|
| `DPOP_KEY_MISSING`   | Key pair no longer exists in the KeyStore                                    | Clear stored credentials |
| `DPOP_NOT_CONFIGURED`| `AuthenticationAPIClient` was not configured with `useDPoP(context)`         | No credentials cleared   |
| `DPOP_KEY_MISMATCH`  | Current key's thumbprint ≠ thumbprint that was saved when credentials stored | Clear stored credentials |

Validation runs before token renewal in `getCredentials()`, `getRevokeCredentials()`, and
`getCredentialsForAudience()`. The thumbprint (JWK representation of the current public key) is
stored alongside credentials and updated on every successful credential save.

---

## Platform Mapping

| Android Concept                       | Swift Equivalent                                         |
|---------------------------------------|----------------------------------------------------------|
| `CredentialsManagerException.Code`    | `CredentialsManagerError.Code` (inner `enum`)            |
| `DPoPUtil.hasKeyPair()`               | `authentication.dpop?.hasKeypair()` (`throws DPoPError`) |
| `authenticationClient.isDPoPEnabled`  | `authentication.dpop != nil`                             |
| `DPoPUtil.getPublicKeyJWK()`          | `authentication.dpop?.jkt()` (returns JWK thumbprint)    |
| `storage.store(KEY_DPOP_THUMBPRINT)`  | `storage.setEntry(_:forKey:)` with UTF-8 Data encoding   |
| `storage.retrieveString(KEY)`         | `storage.getEntry(forKey:)` + UTF-8 decode               |
| `storage.remove(KEY)`                 | `storage.deleteEntry(forKey:)` (swallow not-found error) |
| Android `KeyStore`                    | Keychain / Secure Enclave via `DPoPKeyStore` protocol    |

---

## API Surface

### 1. New error codes in `CredentialsManagerError.Code`

```swift
case dpopKeyMissing
case dpopKeyMismatch
case dpopNotConfigured
```

### 2. New public static error properties in `CredentialsManagerError`

```swift
/// The stored credentials are DPoP-bound but the DPoP key pair is no longer available in the Keychain.
/// Stored credentials are cleared automatically when this error is returned.
/// This error does not include a ``Auth0Error/cause-9wuyi``.
public static let dpopKeyMissing: CredentialsManagerError

/// The stored credentials are DPoP-bound but the `Authentication` client used by this
/// `CredentialsManager` was not configured with DPoP via `.useDPoP()`.
/// This error does not include a ``Auth0Error/cause-9wuyi``.
public static let dpopNotConfigured: CredentialsManagerError

/// The stored credentials are DPoP-bound but the current DPoP key pair does not match the one
/// used when the credentials were saved.
/// Stored credentials are cleared automatically when this error is returned.
/// This error does not include a ``Auth0Error/cause-9wuyi``.
public static let dpopKeyMismatch: CredentialsManagerError
```

### 3. New internal constant in `CredentialsManager`

```swift
private let dpopThumbprintKey = "com.auth0.credentials_manager.dpop_thumbprint"
```

### 4. New internal helper methods in `CredentialsManager`

```swift
/// Validates that stored DPoP-bound credentials are consistent with the current runtime state.
/// Returns an error if validation fails, nil if credentials are not DPoP-bound or all checks pass.
private func validateDPoPState(for credentials: Credentials) -> CredentialsManagerError?

/// Saves (or removes) the current DPoP key thumbprint alongside the given credentials.
private func saveDPoPThumbprint(for credentials: Credentials)
```

### 5. Updated `clear()` method

The `clear()` method will additionally delete the stored DPoP thumbprint entry.

---

## File Organization

```
Auth0/
└── CredentialsManagerError.swift    # Add 3 new codes + static properties + messages
└── CredentialsManager.swift         # Add dpopThumbprintKey, validateDPoPState, saveDPoPThumbprint,
                                     # hook validation into retrieve paths, update clear()
Auth0Tests/
└── CredentialsManagerErrorSpec.swift  # Add tests for 3 new error messages + equality
└── CredentialsManagerSpec.swift       # Add tests for validateDPoPState scenarios and
                                       # saveDPoPThumbprint scenarios
```

---

## Validation Logic (`validateDPoPState`)

```
1. Read stored thumbprint from storage[dpopThumbprintKey]
2. Determine if credentials are DPoP-bound:
   - credentials.tokenType.caseInsensitiveCompare("DPoP") == .orderedSame
   - OR storedThumbprint != nil
   - If NOT DPoP-bound → return nil (no validation needed)

3. Check if DPoP key exists:
   - Call authentication.dpop?.hasKeypair()
   - If dpop is nil OR hasKeypair() returns false or throws:
     → try? self.clear()
     → return .dpopKeyMissing

4. Check if authentication client is DPoP-configured:
   - If authentication.dpop == nil → return .dpopNotConfigured
   (Note: if we reached step 3 and dpop was nil, we'd have returned .dpopKeyMissing already.
    This check is a logical safety net for edge cases.)

5. Check key thumbprint match:
   - currentThumbprint = try? authentication.dpop?.jkt()
   - If storedThumbprint != nil && storedThumbprint != currentThumbprint:
     → try? self.clear()
     → return .dpopKeyMismatch

6. Return nil (all checks passed)
```

**Integration points (where `validateDPoPState` is called):**
- `retrieveCredentialsWithRetry` — before token renewal begins
- `retrieveAPICredentials` (private) — before API token exchange begins
- `retrieveSSOCredentials` — before SSO token exchange begins

---

## Thumbprint Save/Clear Logic (`saveDPoPThumbprint`)

```
1. Check if DPoP was used:
   - credentials.tokenType.caseInsensitiveCompare("DPoP") == .orderedSame
   - OR authentication.dpop != nil
   - If NOT used: try? storage.deleteEntry(forKey: dpopThumbprintKey); return

2. Get current thumbprint:
   - thumbprint = try? authentication.dpop?.jkt()
   - If nil: try? storage.deleteEntry(forKey: dpopThumbprintKey); return

3. Store: try? storage.setEntry(Data(thumbprint.utf8), forKey: dpopThumbprintKey)
```

`saveDPoPThumbprint` is called right after every successful `store(credentials:)` in the renewal path.

---

## Edge Cases & Error Handling

| Scenario                                                            | Behavior                              |
|---------------------------------------------------------------------|---------------------------------------|
| Credentials are not DPoP-bound (Bearer token, no stored thumbprint) | Validation is skipped entirely        |
| `hasKeypair()` throws `DPoPError`                                   | Treated as missing → `.dpopKeyMissing` |
| `jkt()` throws `DPoPError`                                          | Treated as nil thumbprint → skip mismatch check |
| `clear()` fails during validation cleanup                           | Error swallowed (`try?`); original DPoP error still returned |
| Thumbprint storage `setEntry` fails                                 | Swallowed (`try?`); token renewal already succeeded |
| `deleteEntry` on non-existent thumbprint key during `clear()`       | Swallowed (`try?`) - not treated as failure |

---

## Breaking Changes

None. All new error cases are additive. Existing `switch` statements on `CredentialsManagerError`
that handle `.unknown` as the default would naturally catch these new cases, but no existing behavior
is changed.

---

## Test Strategy

### `CredentialsManagerErrorSpec.swift`
- `.dpopKeyMissing` → correct message, no cause, equality/pattern matching
- `.dpopNotConfigured` → correct message, no cause, equality/pattern matching
- `.dpopKeyMismatch` → correct message, no cause, equality/pattern matching

### `CredentialsManagerSpec.swift` — new DPoP validation scenarios (via `credentials()`)

**Not DPoP-bound (baseline):**
- Non-DPoP credentials with no stored thumbprint → validation skipped, renewal proceeds normally

**DPoP-bound credentials (tokenType = "DPoP"):**
- Key missing (hasKeypair returns false) → clears credentials, returns `.dpopKeyMissing`
- Key missing (hasKeypair throws) → clears credentials, returns `.dpopKeyMissing`
- DPoP not configured (authentication.dpop == nil) → returns `.dpopNotConfigured`
- Key thumbprint matches → validation passes, renewal proceeds
- Key thumbprint mismatch → clears credentials, returns `.dpopKeyMismatch`

**DPoP-bound credentials (via stored thumbprint only):**
- Key missing → clears credentials, returns `.dpopKeyMissing`
- DPoP not configured → returns `.dpopNotConfigured`
- Thumbprint matches → validation passes
- Thumbprint mismatch → clears credentials, returns `.dpopKeyMismatch`

**Save thumbprint scenarios:**
- After successful renewal with DPoP credentials → thumbprint stored
- After successful renewal with Bearer credentials → thumbprint removed

**Clear scenarios:**
- `clear()` → DPoP thumbprint also deleted from storage

**Anti-patterns (will NOT test):**
- Getter/setter behavior on `CredentialsManagerError.Code`

---

## Docs Updates

- `CredentialsManagerError.swift`: DocC `///` comments for all three new static properties
- `CredentialsManager.swift`: Update `credentials()` doc to mention DPoP validation errors
- `EXAMPLES.md` (if present): Add DPoP error handling example

---

## Rollback Plan

New error codes are purely additive. If issues are found, no migration is needed — the three cases can be removed without affecting existing functionality.
