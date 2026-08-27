### Delete an authentication method

**Scopes required:** `delete:me:authentication_methods`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .deleteAuthenticationMethod(by: id)
    .start { result in
        switch result {
        case .success:
            print("Authentication method is successfully deleted")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let _ = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .deleteAuthenticationMethod(by: id)
        .start()
    print("Authentication method is successfully deleted")
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
    .deleteAuthenticationMethod(by: id)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { _ in
        print("Authentication method is successfully deleted")
    })
    .store(in: &cancellables)
```
</details>
