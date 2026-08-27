### Get an authentication method by id

**Scopes required:** `read:me:authentication_methods`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .getAuthenticationMethod(by: id)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Obtained authentication method: \(authenticationMethod)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let authenticationMethod = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .getAuthenticationMethod(by: id)
        .start()
    print("Obtained authentication method: \(authenticationMethod)")
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
    .getAuthenticationMethod(by: id)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Obtained authentication method: \(authenticationMethod)")

    })
    .store(in: &cancellables)
```
</details>
