### IPSIE session expiry [EA]

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). It requires session-expiry enforcement enabled on your OIDC or Okta enterprise connection in the Auth0 Dashboard.

Auth0 supports the [IPSIE SL1](https://openid.github.io/ipsie-openid-sl1/draft-openid-ipsie-sl1-profile.html) `session_expiry` claim, which lets an upstream identity provider (e.g. Okta) set a hard ceiling on how long an Auth0-issued session may live. When your connection has this option enabled, Auth0 includes a `session_expiry` Unix timestamp in the ID token it returns to your app after login.

The `CredentialsManager` enforces this ceiling on every retrieval — `credentials()`, `ssoCredentials()`, and `apiCredentials()`. Once the ceiling has passed (with a 30-second clock-skew leeway), the call clears the stored credentials and returns a `CredentialsManagerError.sessionExpired` error instead of attempting a token renewal. No code changes are needed to opt in — the enforcement is transparent once the connection option is active on your tenant.

The ceiling is **pinned at the initial login**: the `session_expiry` value from the first ID token is persisted to the Keychain and never overwritten by a refresh-token grant. This means a renewal whose ID token re-emits the claim cannot raise the ceiling past the original value. `clear()` removes the pinned value on logout so the next login pins a fresh ceiling.

#### What `session_expiry` means

| Claim | Bounds | SDK behaviour |
|---|---|---|
| `exp` | ID token lifetime (minutes) | Already validated on login |
| `session_expiry` | RP session ceiling (hours / days) | **Enforced by `CredentialsManager`** — returns `.sessionExpired` when reached |

#### Handling the error

When `session_expiry` is reached, `credentials()` returns `CredentialsManagerError.sessionExpired`. Your existing "no credentials" re-login path already handles this — or you can match the case explicitly:

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
    case .failure(CredentialsManagerError.sessionExpired):
        // Upstream IdP session has ended — send the user back to login
        Auth0.webAuth().start { _ in }
    case .failure(let error):
        print("Failed with: \(error)")
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await credentialsManager.credentials()
    print("Obtained credentials: \(credentials)")
} catch CredentialsManagerError.sessionExpired {
    // Upstream IdP session has ended — send the user back to login
    let _ = try? await Auth0.webAuth().start()
} catch {
    print("Failed with: \(error)")
}
```
</details>

> [!NOTE]
> **Upgrading existing apps.** Sessions stored before the `session_expiry` option was enabled on your connection carry no ceiling and behave exactly as before — `.sessionExpired` is never returned for them. Once the option is turned on, `credentials()` can return `.sessionExpired` for a user who is already logged in, as soon as their ceiling passes. Any code that assumed a stored session stays usable until the access token expires now has this additional failure path to handle. Treat it the same way you would `CredentialsManagerError.noCredentials`: clear the local session and redirect the user to log in again.

#### Reading the `session_expiry` value

`Credentials` exposes the ceiling via the `sessionExpiresAt` property (`Date`, or `nil` when the connection does not emit the claim), which you can use for app-level logic such as a countdown timer:

```swift
credentialsManager.credentials { result in
    guard case .success(let credentials) = result,
          let sessionExpiresAt = credentials.sessionExpiresAt else { return }
    print("Session ceiling: \(sessionExpiresAt)")
}
```

> [!NOTE]
> `sessionExpiresAt` reflects the `session_expiry` claim in the *current* ID token only. The `CredentialsManager` enforces the ceiling pinned at the initial login, which may differ from — or be absent from — a later renewal token. For the authoritative ceiling value, rely on the `CredentialsManager` error, not this property.

> [!IMPORTANT]
> `session_expiry` is a ceiling computed at login time — it is **not** real-time session revocation. If a user is de-provisioned mid-session, they will not be immediately signed out; that requires back-channel logout / CAEP, which is a separate platform capability.

[Go up ⤴](../../EXAMPLES.md)
