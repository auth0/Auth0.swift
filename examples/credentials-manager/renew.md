### Renew stored credentials

The `credentials()` method automatically renews the stored credentials when needed, using the [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens). However, you can also force a renewal using the `renew()` method. **This method is thread-safe**.

See [Get a refresh token](../web-auth/configuration.md#get-a-refresh-token) to learn how to obtain a refresh token.

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
