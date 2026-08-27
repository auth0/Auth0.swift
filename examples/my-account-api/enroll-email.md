### Enroll a new email authentication method

**Scopes required:** `create:me:authentication_methods`

Enrolling a new email authentication method is a two-step process. First, you request an enrollment challenge from Auth0. Then, you use the original challenge to enroll the email authentication method with Auth0.

#### Prerequisites

- Enable the MFA grant type for your application. Go to Auth0 Dashboard > Applications > Advanced Settings > Grant Types and select MFA.
- Enable the Email factor. Go to Auth0 Dashboard > Security > Multi-factor Auth > Email.
- The iOS **Device Settings** configured for your Auth0 application.

#### 1. Request an enrollment challenge

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enrollEmail(emailAddress: emailAddress)
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
        .enrollEmail(emailAddress: emailAddress)
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
    .enrollEmail(emailAddress: emailAddress)
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

#### 2. Enroll the email authentication method

Use the otpCode received in the email used for generating enrollment challenge, authSession and id from enrollment challenge to enroll the email with Auth0.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .confirmEmailEnrollment(id: id,
                           authSession: authSession,
                           otpCode: otpCode)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled email: \(authenticationMethod)")
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
        .confirmEmailEnrollment(id: id,
                                authSession: authSession,
                                otpCode: otpCode)
        .start()
    print("Enrolled email: \(authenticationMethod)")
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
    .confirmEmailEnrollment(id: id,
                            authSession: authSession,
                            otpCode: otpCode)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled email: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>
