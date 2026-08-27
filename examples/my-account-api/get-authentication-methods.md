### Get all authentication methods

**Scopes required:** `read:me:authentication_methods`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .getAuthenticationMethods()
    .start { result in
        switch result {
        case .success(let authenticationMethods):
            print("Obtained authentication methods: \(authenticationMethods)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let authenticationMethods = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .getAuthenticationMethods()
        .start()
    print("Obtained authentication methods: \(authenticationMethods)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .getAuthenticationMethods()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethods in
        print("Obtained authentication methods: \(authenticationMethods)")
    })
    .store(in: &cancellables)
```
</details>
