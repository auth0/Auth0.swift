## Credentials Manager (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanager)**

> [!NOTE]
> All completion callbacks in Auth0.swift execute on the main thread, making it safe to update UI directly. If needed, explicitly dispatch to a background thread.

- [Store credentials](store.md#store-credentials)
- [Check for stored credentials](check-stored.md#check-for-stored-credentials)
- [Retrieve stored credentials](retrieve.md#retrieve-stored-credentials)
- [Renew stored credentials](renew.md#renew-stored-credentials)
- [Retrieve stored user information](user-information.md#retrieve-stored-user-information)
- [Clear stored credentials](clear.md#clear-stored-credentials)
- [Biometric authentication](biometric-authentication.md#biometric-authentication)
- [IPSIE session expiry \[EA\]](ipsie-session-expiry.md#ipsie-session-expiry-ea)
- [Other credentials](other-credentials.md#other-credentials)
- [Credentials Manager errors](errors.md#credentials-manager-errors)

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
