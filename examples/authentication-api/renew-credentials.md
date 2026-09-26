### Renew credentials

Use a [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens) to renew the user's credentials. It is recommended that you read and understand the refresh token process beforehand.

See [Get a refresh token](../web-auth.md#get-a-refresh-token) to learn how to obtain a refresh token.

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained new credentials")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .renew(withRefreshToken: credentials.refreshToken)
        .start()
    print("Obtained new credentials")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .renew(withRefreshToken: credentials.refreshToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained new credentials")
    })
    .store(in: &cancellables)
```
</details>
