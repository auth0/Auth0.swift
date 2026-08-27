### Get all factors

**Scopes required:** `read:me:factors`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .getFactors()
    .start { result in
        switch result {
        case .success(let factors):
            print("Obtained factors: \(factors)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let factors = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .getFactors()
        .start()
    print("Obtained factors: \(factors)")
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
    .getFactors()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { factors in
        print("Obtained factors: \(factors)")
    })
    .store(in: &cancellables)
```
</details>
