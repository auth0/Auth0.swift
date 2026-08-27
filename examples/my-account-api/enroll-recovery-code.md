### Enroll a new recovery code authentication method

**Scopes required:** `create:me:authentication_methods`

Enrolling a new recovery code authentication method is a two-step process. First, you request an enrollment challenge from Auth0. Then, you use the original challenge to enroll the recovery code authentication method with Auth0.

#### Prerequisites

- Enable the MFA grant type for your application. Go to Auth0 Dashboard > Applications > Advanced Settings > Grant Types and select MFA.
- Enable the Email factor. Go to Auth0 Dashboard > Security > Multi-factor Auth > Recovery Code.
- The iOS **Device Settings** configured for your Auth0 application.

#### 1. Request an enrollment challenge

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enrollRecoveryCode()
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
        .enrollRecoveryCode()
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
    .enrollRecoveryCode()
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

#### 2. Enroll the recovery code authentication method

Use the authSession and id from enrollment challenge to enroll the recovery code with Auth0.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .confirmRecoveryCodeEnrollment(id: id,
                                   authSession: authSession)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled recovery code: \(authenticationMethod)")
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
        .confirmRecoveryCodeEnrollment(id: id,
                                       authSession: authSession)
        .start()
    print("Enrolled Recovery code: \(authenticationMethod)")
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
    .confirmRecoveryCodeEnrollment(id: id,
                                   authSession: authSession)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled recovery code: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>
