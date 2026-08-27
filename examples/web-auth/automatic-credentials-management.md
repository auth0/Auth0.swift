### Automatic credentials management

You can pass a `CredentialsManager` instance to the Web Auth client to automatically store credentials after a successful login and clear them after a successful logout. If no credentials manager is set, credentials are returned directly without being stored.

```swift
let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

// Credentials are automatically stored after login
let credentials = try await Auth0
    .webAuth()
    .useCredentialsManager(credentialsManager)
    .start()

// Later, retrieve stored credentials using the same instance
let storedCredentials = try await credentialsManager.credentials()

// Credentials are automatically cleared after logout
try await Auth0
    .webAuth()
    .useCredentialsManager(credentialsManager)
    .logout()
```

> [!IMPORTANT]
> Call `useCredentialsManager(_:)` on **both** your `start()` and `logout()` call chains. Omitting it on `logout()` will succeed but credentials will **not** be cleared automatically. Do not manually call `store(credentials:)` after login or `clear()` after logout on the same instance — doing so can lead to race conditions or inconsistent state.

> [!NOTE]
> If the credentials manager fails to store or clear credentials, a `WebAuthError.credentialsManagerError` will be thrown. The underlying error can be accessed via the `cause` property.
