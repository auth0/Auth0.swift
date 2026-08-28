## Credentials Manager (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanager)**

> [!NOTE]
> All completion callbacks in Auth0.swift execute on the main thread, making it safe to update UI directly. If needed, explicitly dispatch to a background thread.

- [Store credentials](#store-credentials)
- [Check for stored credentials](#check-for-stored-credentials)
- [Retrieve stored credentials](#retrieve-stored-credentials)
- [Renew stored credentials](#renew-stored-credentials)
- [Retrieve stored user information](#retrieve-stored-user-information)
- [Clear stored credentials](#clear-stored-credentials)
- [Biometric authentication](#biometric-authentication)
- [IPSIE session expiry \[EA\]](#ipsie-session-expiry-ea)
- [Other credentials](#other-credentials)
- [Credentials Manager errors](#credentials-manager-errors)

The Credentials Manager utility allows you to securely store and retrieve the user's credentials from the Keychain.

```swift
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
```

> [!CAUTION]
> The Credentials Manager is not thread-safe, except for the following methods: 
> 
> - `credentials()`
> - `apiCredentials()`
> - `ssoCredentials()`
> - `renew()`
> 
> To avoid concurrency issues, do not call its non thread-safe methods and properties from different threads without proper synchronization.

> [!NOTE]
> **Swift 6 Sendability Support**: The Credentials Manager conforms to `Sendable`, which allows it to be passed across concurrency boundaries (like into actors). However, this does **not** make all its methods thread-safe. Only the methods listed above (`credentials()`, `apiCredentials()`, `ssoCredentials()`, `renew()`) are thread-safe. Other methods and properties still require proper synchronization when called from multiple threads.
>
> ```swift
> // Example: Using CredentialsManager in an Actor (Swift 6)
> actor AuthService {
>     let credentialsManager: CredentialsManager
>     
>     init() {
>         self.credentialsManager = CredentialsManager(authentication: Auth0.authentication())
>     }
>     
>     func fetchCredentials() async throws -> Credentials {
>         // Safe to call from within an actor
>         return try await credentialsManager.credentials(withScope: "openid profile email",
>                                                         parameters: [:],
>                                                         headers: [:])
>     }
> }
> ```
>
> The default `minTTL` is 60 seconds. You can override it if needed:
>
> ```swift
> let credentials = try await credentialsManager.credentials(minTTL: 120)
> ```

### Store credentials

When your users log in, store their credentials securely in the Keychain. You can then check if their credentials are still valid when they open your app again.

```swift
do {
    try credentialsManager.store(credentials: credentials)
} catch {
    print("Failed to store credentials: \(error)")
}
```

### Check for stored credentials

When the users open your app, check for stored credentials. If they exist and are valid / can be renewed, you can retrieve them and redirect the users to the app's main flow without any additional login steps.

#### If you are using refresh tokens

```swift
guard credentialsManager.canRenew() else {
    // No renewable credentials exist, present the login page
}
// Retrieve the stored credentials
```

See [Get a refresh token](web-auth.md#get-a-refresh-token) to learn how to obtain a [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens).

#### If you are not using refresh tokens

```swift
guard credentialsManager.hasValid() else {
    // No valid credentials exist, present the login page
}
// Retrieve the stored credentials
```

### Retrieve stored credentials

The credentials will be automatically renewed (if expired) using the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens). **This method is thread-safe.**

See [Get a refresh token](web-auth.md#get-a-refresh-token) to learn how to obtain a refresh token.

```swift
credentialsManager.credentials { result in 
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
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
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .credentials()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!CAUTION]
> Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the renewed credentials. Since this method is thread-safe and `store(credentials:)` is not, calling it anyway can cause concurrency issues.

> [!CAUTION]
> To ensure that no concurrent renewal requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

#### Automatic retry on transient errors

The Credentials Manager includes automatic retry logic for credential renewal when transient errors occur. This helps handle scenarios where network requests fail temporarily, such as:

- Network connectivity issues (timeouts, connection lost, DNS failures)
- Rate limiting responses (HTTP 429)
- Server errors (HTTP 5xx)

**How it works:**

When a renewal request fails due to a transient error, the Credentials Manager will automatically retry the request with exponential backoff (0.5s, 1s, 2s, 4s, etc.). This addresses the following scenario:

1. Request A calls `credentials()` and starts a token refresh
2. Request A successfully hits the server and gets new credentials
3. Request A fails on the way back (network issue), never reaching the client
4. The retry mechanism automatically retries the failed request using the same (old) refresh token

To fully leverage the retry mechanism, ensure your Auth0 tenant's **Rotation Overlap Period** is set to at least 180 seconds. This overlap window ensures the old refresh token remains valid during retry attempts even if the backend resource was already updated. You can configure this setting in your Auth0 Dashboard under **Applications > [Your Application] > Settings > Refresh Token Rotation**.

**Configure retry behavior:**

By default, retries are disabled. You can enable retries by specifying a maximum retry count when creating the Credentials Manager. It is advisable to set a maximum of 2 retries, which provides sufficient resilience without introducing excessive delays or unnecessary network requests.

```swift
// Enable 1 retry attempt
let credentialsManager = CredentialsManager(
    authentication: Auth0.authentication(),
    maxRetries: 1
)
```


**Important considerations:**

- Retries only occur for transient errors (network issues, rate limiting, server errors)
- Permanent errors (invalid refresh token, authorization failures) will not be retried
- Each retry uses exponential backoff to avoid overwhelming the server
- The 180-second refresh token overlap window ensures retries can succeed even after a successful backend renewal

### Renew stored credentials

The `credentials()` method automatically renews the stored credentials when needed, using the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens). However, you can also force a renewal using the `renew()` method. **This method is thread-safe**.

See [Get a refresh token](web-auth.md#get-a-refresh-token) to learn how to obtain a refresh token.

```swift
credentialsManager.renew { result in
    switch result {
    case .success(let credentials):
        print("Renewed credentials: \(credentials)")
    case .failure(let error):
        print("Failed with: \(error)")
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await credentialsManager.renew()
    print("Renewed credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .renew()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Renewed credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!CAUTION]
> Do not call `store(credentials:)` afterward. The Credentials Manager automatically persists the renewed credentials. Since this method is thread-safe and `store(credentials:)` is not, calling it anyway can cause concurrency issues.

> [!CAUTION]
> To ensure that no concurrent renewal requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

### Retrieve stored user information

The stored [ID token](https://auth0.com/docs/secure/tokens/id-tokens) contains a copy of the user information at the time of authentication (or renewal, if the credentials were renewed). That user information can be retrieved from the Keychain synchronously, without checking if the credentials expired.

```swift
do {
    let user = try credentialsManager.userProfile()
} catch {
    print("Failed to retrieve user profile: \(error)")
}
```

To get the latest user information, you can use the `renew()` [method](#renew-stored-credentials). Calling this method will automatically update the stored user information. You can also use the `userInfo(withAccessToken:)` [method](authentication-api/user-information.md#retrieve-user-information) of the Authentication API client, but it will not update the stored user information.

### Clear stored credentials

The stored credentials can be removed from the Keychain by using the `clear()` method.

```swift
do {
    try credentialsManager.clear()
} catch {
    print("Failed to clear credentials: \(error)")
}
```

### Clear all stored credentials

To remove **all** credentials stored by the Credentials Manager from the Keychain —including the default credentials entry and any API credentials stored for different audiences— use the `clearAll()` method.

```swift
do {
    try credentialsManager.clearAll()
} catch {
    print("Failed to clear all credentials: \(error)")
}
```

> [!NOTE]
> `clearAll()` delegates to the underlying storage's `deleteAllEntries()` method, which removes all entries for the configured service/access group. Ensure the storage is dedicated to Auth0 credentials to avoid unintended data loss.

This is different from `clear()`, which only removes the default credentials entry.

### Biometric authentication

You can enable an additional level of user authentication before retrieving credentials using the biometric authentication supported by the device, such as Face ID or Touch ID.

```swift
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID")
```

If needed, you can specify a particular `LAPolicy` to be used. For example, you might want to support Face ID or Touch ID, but also allow fallback to passcode.

```swift
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID or passcode", 
                                    evaluationPolicy: .deviceOwnerAuthentication)
```

#### Biometric Policy

You can configure a `BiometricPolicy` to control when biometric authentication is required. There are four types of policies available:

- **`.default`**: Uses the same `LAContext` instance, allowing the system to manage biometric prompts. The system may skip the prompt if biometric authentication was recently successful. This is the default policy and preserves backward-compatible behavior.
- **`.always`**: Requires biometric authentication every time credentials are accessed. Creates a fresh `LAContext` for each authentication to ensure a new prompt is always shown.
- **`.session(timeoutInSeconds:)`**: Requires biometric authentication only if the specified time (in seconds) has passed since the last successful authentication. Creates a fresh `LAContext` when the session has expired.
- **`.appLifecycle(timeoutInSeconds:)`**: Similar to the session policy, but the session persists for the lifetime of the app process. Creates a fresh `LAContext` when the session has expired. The default timeout is 1 hour (3600 seconds).

> [!NOTE]
> The `.always`, `.session`, and `.appLifecycle` policies create a new `LAContext` for each authentication attempt (when required), ensuring that the biometric prompt is shown reliably. The `.default` policy reuses the same context, which allows the system to optimize prompt frequency.

**Examples:**

```swift
// Default behavior - system manages biometric prompts (default)
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .default)

// Always require biometric authentication with fresh prompt
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .always)

// Require authentication only once per 5-minute session
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .session(timeoutInSeconds: 300))

// Require authentication once per app lifecycle (1 hour default)
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .appLifecycle()) // Default: 3600 seconds (1 hour)
```

**Managing Biometric Sessions:**

You can manually clear the biometric session to force re-authentication on the next credential access:

```swift
// Clear the biometric session
credentialsManager.clearBiometricSession()

// Check if the current session is valid
let isValid = credentialsManager.isBiometricSessionValid()
```

> [!NOTE]
> Retrieving the user information with `credentialsManager.userProfile()` will not be protected by biometric authentication.

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

[Go up ⤴](../EXAMPLES.md#examples)

### Other credentials

#### API credentials [EA]

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

When the user logs in, you can request an access token for a specific API by passing its API identifier as the [audience](web-auth.md#add-an-audience-value) value. The access token in the resulting credentials can then be used to make authenticated requests to that API.

However, if you need an access token for a different API, you can exchange the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) for credentials containing an access token specific to this other API. **This method is thread-safe**.

> [!IMPORTANT]
> Currently, only the Auth0 My Account API is supported. Support for other APIs will be added in the future.

```swift
credentialsManager.apiCredentials(forAudience: "https://example.com/me",
                                  scope: "create:me:authentication_methods") { result in
    switch result {
    case .success(let apiCredentials):
        print("Obtained API credentials: \(apiCredentials)")
    case .failure(let error):
        print("Failed with: \(error)")
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let apiCredentials = try await credentialsManager.apiCredentials(forAudience: "https://example.com/me",
                                                                     scope: "create:me:authentication_methods")
    print("Obtained API credentials: \(apiCredentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .apiCredentials(forAudience: "https://example.com/me",
                    scope: "create:me:authentication_methods")
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { apiCredentials in
        print("Obtained API credentials: \(apiCredentials)")
    })
    .store(in: &cancellables)
```
</details>

See [Get a refresh token](web-auth.md#get-a-refresh-token) to learn how to obtain a refresh token.

> [!CAUTION]
> To ensure that no concurrent exchange requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

#### SSO credentials

To implement single sign-on (SSO) with Universal Login, you can use either `ASWebAuthenticationSession` or `SFSafariViewController` as the in-app browser. Each [has its own advantages and disadvantages](https://auth0.github.io/Auth0.swift/documentation/auth0/useragents), and suit different use cases.

An alternative way to implement SSO is by making use of a session transfer token. This is a single-use, short-lived token you must send to your website –either via query parameter or cookie– when opening it from your app. Your website then needs to redirect the user to Auth0's `/authorize` endpoint, passing along the session transfer token. Auth0 will set the respective session cookies and then redirect the user back to your website. Now, the user will be logged in on your website too. **This solution will work with any browser and webview –even standalone browser apps**.

First, you need to exchange the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) for a set of SSO credentials containing a session transfer token. **This method is thread-safe**.

```swift
credentialsManager.ssoCredentials { result in
    switch result {
    case .success(let ssoCredentials):
        print("Obtained SSO credentials: \(ssoCredentials)")
    case .failure(let error):
        print("Failed with: \(error)")
    }
}
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let ssoCredentials = try await credentialsManager.ssoCredentials()
    print("Obtained SSO credentials: \(ssoCredentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
credentialsManager
    .ssoCredentials()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { ssoCredentials in
        print("Obtained SSO credentials: \(ssoCredentials)")
    })
    .store(in: &cancellables)
```
</details>

See [Get a refresh token](web-auth.md#get-a-refresh-token) to learn how to obtain a refresh token.

> [!CAUTION]
> To ensure that no concurrent exchange requests get made, do not call this method from multiple Credentials Manager instances. The Credentials Manager cannot synchronize requests across instances.

Then, when opening your website on any browser or web view, add the session transfer token to the URL as a query parameter.
For example, `https://example.com/login?session_transfer_token=THE_TOKEN`.

If you're using `WKWebView` to open your website, you can place the session transfer token inside a cookie instead. It will be automatically sent to the `/authorize` endpoint.

```swift
let cookie = HTTPCookie(properties: [
    .domain: "YOUR_AUTH0_DOMAIN", // Or custom domain, if your website is using one
    .path: "/",
    .name: "auth0_session_transfer_token",
    .value: ssoCredentials.sessionTransferToken,
    .expires: ssoCredentials.expiresAt,
    .secure: true
])!

webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
```

> [!IMPORTANT]
> Make sure the cookie's domain matches the Auth0 domain your *website* is using, regardless of the one your mobile app is using. Otherwise, the `/authorize` endpoint will not receive the cookie. If your website is using the default Auth0 domain (like `example.us.auth0.com`), set the cookie's domain to this value. On the other hand, if your website is using a custom domain, use this value instead.

### Credentials Manager errors

The Credentials Manager will only produce `CredentialsManagerError` error values. You can find the underlying error (if any) in the `cause: Error?` property of the `CredentialsManagerError`. Not all error cases will have an underlying `cause`. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanagererror) to learn more about the error cases you need to handle, and which ones include a `cause` value.

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
    case .failure(let error):
        switch error {
        case CredentialsManagerError.noCredentials:
            // No credentials stored — prompt login
            break
        case CredentialsManagerError.noRefreshToken:
            // Credentials expired and no refresh token — prompt login
            break
        case CredentialsManagerError.renewFailed:
            // Token renewal failed — check error.cause for details
            break
        case CredentialsManagerError.storeFailed:
            // Failed to save renewed credentials to Keychain
            break
        case CredentialsManagerError.clearFailed:
            // Failed to remove credentials from Keychain
            break
        case CredentialsManagerError.biometricsFailed:
            // Biometric authentication failed — check error.cause for details
            break
        case CredentialsManagerError.revokeFailed:
            // Token revocation failed — check error.cause for details
            break
        case CredentialsManagerError.sessionExpired:
            // Upstream IdP session ceiling reached — prompt re-login
            break
        default:
            break
        }
    }
}
```

To revoke the stored refresh token and clear credentials, use the `revoke()` method:

```swift
credentialsManager.revoke { result in
    switch result {
    case .success:
        // Refresh token revoked and credentials cleared
        break
    case .failure(let error):
        switch error {
        case CredentialsManagerError.noCredentials:
            // No credentials in storage — nothing to revoke
            break
        case CredentialsManagerError.revokeFailed:
            // Network revocation failed — the refresh token may still be active
            break
        case CredentialsManagerError.clearFailed:
            // Token was revoked but credentials could not be removed from storage
            break
        default:
            break
        }
    }
}
```

#### DPoP error handling

When using DPoP with the Credentials Manager, additional validation is performed on credential retrieval to ensure the DPoP key pair is consistent. The following errors may be returned:

- **`dpopNotConfigured`**: The stored credentials are DPoP-bound but the `Authentication` client was not configured with DPoP via `.useDPoP()`. Ensure the `Authentication` client used by the `CredentialsManager` has DPoP enabled.

- **`dpopKeyMissing`**: The DPoP key pair is no longer available in the Keychain (e.g., due to app reinstall or Keychain reset). Stored credentials are cleared automatically. The user must log in again.

- **`dpopKeyMismatch`**: The current DPoP key pair does not match the one used when the credentials were saved. Stored credentials are cleared automatically. The user must log in again.

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
    case .failure(let error):
        switch error {
        case .dpopNotConfigured:
            // Authentication client was not configured with .useDPoP().
            // Fix the CredentialsManager initialisation:
            //   CredentialsManager(authentication: Auth0.authentication().useDPoP())
            break
        case .dpopKeyMissing:
            // DPoP key was lost (e.g. app reinstall). Prompt user to re-authenticate.
            break
        case .dpopKeyMismatch:
            // DPoP key doesn't match the one used at login. Prompt user to re-authenticate.
            break
        default:
            print("Failed with: \(error)")
        }
    }
}
```

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Run a switch statement on the [error cases](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanagererror/#topics) instead, which are part of the API.

[Go up ⤴](../EXAMPLES.md#examples)
