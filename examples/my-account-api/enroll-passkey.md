### Enroll a new passkey

**Scopes required:** `create:me:authentication_methods`

Enrolling a new passkey is a three-step process. First, you request an enrollment challenge from Auth0. Then, you pass that challenge to Apple's [`AuthenticationServices`](https://developer.apple.com/documentation/authenticationservices) APIs to create a new passkey credential. Finally, you use the created passkey credential and the original challenge to enroll the passkey with Auth0.

#### Prerequisites

- A custom domain configured for your Auth0 tenant.
- The **Passkeys** grant to be enabled for your Auth0 application.
- The iOS **Device Settings** configured for your Auth0 application.

Check [our documentation](https://auth0.com/docs/native-passkeys-for-mobile-applications#before-you-begin) for more information.

#### 1. Request an enrollment challenge

You can specify an optional user identity identifier and/or a database connection name to help Auth0 find the user. The user identity identifier will be needed if the user logged in with a [linked account](https://auth0.com/docs/manage-users/user-accounts/user-account-linking).

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .passkeyEnrollmentChallenge()
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
        .passkeyEnrollmentChallenge()
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
    .passkeyEnrollmentChallenge()
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

#### 2. Create a new passkey credential

Use the enrollment challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider) from the `AuthenticationServices` framework to generate a new passkey credential. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service) to learn more.

```swift
let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: enrollmentChallenge.relyingPartyId
)

let request = credentialProvider.createCredentialRegistrationRequest(
    challenge: enrollmentChallenge.challengeData,
    name: enrollmentChallenge.userName,
    userID: enrollmentChallenge.userId
)

let authController = ASAuthorizationController(authorizationRequests: [request])
authController.delegate = self // ASAuthorizationControllerDelegate
authController.presentationContextProvider = self
authController.performRequests()
```

The created passkey credential will be delivered through the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.

```swift
func authorizationController(controller: ASAuthorizationController,
                             didCompleteWithAuthorization authorization: ASAuthorization) {
    switch authorization.credential {
    case let newPasskey as ASAuthorizationPlatformPublicKeyCredentialRegistration:
        // ...
    default:
        print("Unrecognized credential: \(authorization.credential)")
    }

    // ...
}
```

#### 3. Enroll the passkey

Use the created passkey credential and the enrollment challenge to enroll the passkey with Auth0.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enroll(passkey: newPasskey,
            challenge: enrollmentChallenge)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled passkey: \(authenticationMethod)")
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
        .enroll(passkey: newPasskey,
                challenge: enrollmentChallenge)
        .start()
    print("Enrolled passkey: \(authenticationMethod)")
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
    .enroll(passkey: newPasskey,
            challenge: enrollmentChallenge)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled passkey: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>
