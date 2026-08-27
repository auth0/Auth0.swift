### Enroll a new password authentication method

**Scopes required:** `create:me:authentication_methods`

Enrolling a new password authentication method is a two-step process. First, you request an enrollment challenge, which returns the connection's [password policy](https://auth0.com/docs/authenticate/database-connections/password-options) so you can guide the user to choose a compliant password. Then, you confirm the enrollment with the new password.

#### 1. Request an enrollment challenge

You can specify an optional user identity identifier and/or a database connection name to help Auth0 find the user. The user identity identifier will be needed if the user logged in with a [linked account](https://auth0.com/docs/manage-users/user-accounts/user-account-linking).

> [!NOTE]
> Pass `userIdentityId` **without** the identity provider prefix.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enrollPassword()
    .start { result in
        switch result {
        case .success(let enrollmentChallenge):
            print("Obtained enrollment challenge: \(enrollmentChallenge)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let enrollmentChallenge = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .enrollPassword()
        .start()
    print("Obtained enrollment challenge: \(enrollmentChallenge)")
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
    .enrollPassword()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { enrollmentChallenge in
        print("Obtained enrollment challenge: \(enrollmentChallenge)")
    })
    .store(in: &cancellables)
```
</details>

#### 2. Confirm the enrollment

Use the `policy` from the enrollment challenge to guide the user toward a compliant password, then use the `authenticationId` and `authenticationSession` to confirm the enrollment with the new password.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .confirmPasswordEnrollment(id: id,
                               authSession: authSession,
                               newPassword: newPassword)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled password: \(authenticationMethod)")
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
        .confirmPasswordEnrollment(id: id,
                                   authSession: authSession,
                                   newPassword: newPassword)
        .start()
    print("Enrolled password: \(authenticationMethod)")
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
    .confirmPasswordEnrollment(id: id,
                               authSession: authSession,
                               newPassword: newPassword)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled password: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>
