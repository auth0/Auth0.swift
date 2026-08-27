### Retrieve stored credentials

The credentials will be automatically renewed (if expired) using the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens). **This method is thread-safe.**

See [Get a refresh token](../web-auth/configuration.md#get-a-refresh-token) to learn how to obtain a refresh token.

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
