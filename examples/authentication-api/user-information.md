### Retrieve user information

Fetch the latest user information from the `/userinfo` endpoint.

This method will yield a `UserProfile` instance. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/userprofile) to learn more about its available properties.

```swift
Auth0
   .authentication()
   .userInfo(withAccessToken: credentials.accessToken)
   .start { result in
       switch result {
       case .success(let user):
           print("Obtained user: \(user)")
       case .failure(let error):
           print("Failed with: \(error)")
       }
   }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let user = try await Auth0
        .authentication()
        .userInfo(withAccessToken: credentials.accessToken)
        .start()
    print("Obtained user: \(user)")
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
    .userInfo(withAccessToken: credentials.accessToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { user in
        print("Obtained user: \(user)")
    })
    .store(in: &cancellables)
```
</details>
