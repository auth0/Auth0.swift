### Enroll a new phone authentication method

**Scopes required:** `create:me:authentication_methods`

Enrolling a new phone authentication method is a two-step process. First, you request an enrollment challenge from Auth0. Then, you use the original challenge to enroll the phone authentication method with Auth0.

#### Prerequisites

- Enable the MFA grant type for your application. Go to Auth0 Dashboard > Applications > Advanced Settings > Grant Types and select MFA.
- Enable the Phone Message factor. Go to Auth0 Dashboard > Security > Multi-factor Auth > Phone Message.
- The iOS **Device Settings** configured for your Auth0 application.

#### 1. Request an enrollment challenge

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enrollPhone(phoneNumber: phoneNumber, 
                 preferredAuthenticationMethod: .sms)
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
        .enrollPhone(phoneNumber: phoneNumber, 
                     preferredAuthenticationMethod: .sms)
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
    .enrollPhone(phoneNumber: phoneNumber, 
                 preferredAuthenticationMethod: .sms)
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

#### 2. Enroll the phone authentication method

Use the otpCode received in the phone number used for generating challenge, authSession and id from enrollment challenge to enroll the phone with Auth0.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .confirmPhoneEnrollment(id: id,
                           authSession: authSession,
                           otpCode: otpCode)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled phone: \(authenticationMethod)")
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
        .confirmPhoneEnrollment(id: id,
                               authSession: authSession,
                               otpCode: otpCode)
        .start()
    print("Enrolled phone: \(authenticationMethod)")
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
    .confirmPhoneEnrollment(id: id,
                           authSession: authSession,
                           otpCode: otpCode)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled phone: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>
