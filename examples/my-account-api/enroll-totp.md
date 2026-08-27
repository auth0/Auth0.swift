### Enroll a new TOTP authentication method

**Scopes required:** `create:me:authentication_methods`

Enrolling a new TOTP authentication method is a two-step process. First, you request an enrollment challenge from Auth0. Then, you use the original challenge to enroll the TOTP authentication method with Auth0.

#### Prerequisites

- Enable the MFA grant type for your application. Go to Auth0 Dashboard > Applications > Advanced Settings > Grant Types and select MFA.
- Enable the One-time Password factor. Go to Auth0 Dashboard > Security > Multi-factor Auth > One-time Password.
- The iOS **Device Settings** configured for your Auth0 application.

#### 1. Request an enrollment challenge

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enrollTOTP()
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
        .enrollTOTP()
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
    .enrollTOTP()
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

#### 2. Enroll the TOTP authentication method

Use the otpCode from the authenticator app, authSession and id from enrollment challenge to enroll the TOTP with Auth0.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .confirmTOTPEnrollment(id: id, 
                           authSession: authSession, 
                           otpCode: otpCode)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled TOTP: \(authenticationMethod)")
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
        .confirmTOTPEnrollment(id: id, 
                               authSession: authSession, 
                               otpCode: otpCode)
        .start()
    print("Enrolled TOTP: \(authenticationMethod)")
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
   .confirmTOTPEnrollment(id: id, 
                          authSession: authSession, 
                          otpCode: otpCode)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled TOTP: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>
