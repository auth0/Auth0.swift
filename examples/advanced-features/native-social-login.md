### Native social login

#### Sign in With Apple

If you've added the [Sign In with Apple flow](https://developer.apple.com/documentation/authenticationservices/implementing_user_authentication_with_sign_in_with_apple) to your app, after a successful Sign in With Apple authentication you can use the value of the `authorizationCode` property to perform a code exchange for Auth0 credentials.

```swift
Auth0
    .authentication()
    .login(appleAuthorizationCode: "auth-code")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials")
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
        .login(appleAuthorizationCode: "auth-code")
        .start()
    print("Obtained credentials")
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
    .login(appleAuthorizationCode: "auth-code")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> See the [Setting up Sign In with Apple](https://auth0.com/docs/authenticate/identity-providers/social-identity-providers/apple-native) guide for more information about integrating Sign In with Apple with Auth0.

#### Facebook Login

If you've added the [Facebook Login flow](https://developers.facebook.com/docs/facebook-login/ios) to your app, after a successful Facebook authentication you can request a [session info access token](https://developers.facebook.com/docs/facebook-login/guides/access-tokens/get-session-info) and the Facebook user profile, and then use them both to perform a token exchange for Auth0 credentials.

```swift
Auth0
    .authentication()
    .login(facebookSessionAccessToken: "session-info-access-token",
           profile: ["key": "value"])
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials")
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
        .login(facebookSessionAccessToken: "session-info-access-token",
               profile: ["key": "value"])
        .start()
    print("Obtained credentials")
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
    .login(facebookSessionAccessToken: "session-info-access-token",
           profile: ["key": "value"])
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> See the [Setting up Facebook Login](https://auth0.com/docs/authenticate/identity-providers/social-identity-providers/facebook-native) guide for more information about integrating Facebook Login with Auth0.
