### Sign up with passkey [EA]

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

Signing a user up with a passkey is a three-step process. First, you request a signup challenge from Auth0. Then, you pass that challenge to Apple's [`AuthenticationServices`](https://developer.apple.com/documentation/authenticationservices) APIs to create a **new passkey credential**. Finally, you use the created passkey credential and the original challenge to log the new user in.

#### Prerequisites

- A custom domain configured for your Auth0 tenant.
- The **Passkeys** grant to be enabled for your Auth0 application.
- The iOS **Device Settings** configured for your Auth0 application.

Check [our documentation](https://auth0.com/docs/native-passkeys-for-mobile-applications#before-you-begin) for more information.

#### 1. Request a signup challenge

You need to provide at least one user identifier when requesting the challenge, along with an optional user display name, and an optional database connection name. If a connection name is not specified, your tenant's default directory will be used.

By default, database connections require a valid `email`. If you have enabled [Flexible Identifiers](https://auth0.com/docs/authenticate/database-connections/activate-and-configure-attributes-for-flexible-identifiers) for your database connection, you may use any combination of `email`, `phoneNumber`, or `username`. These user identifiers can be required or optional and must match your Flexible Identifiers configuration.

```swift
Auth0
    .authentication()
    .passkeySignupChallenge(email: "support@auth0.com",
                            name: "John Appleseed",
                            connection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let signupChallenge):
            print("Obtained signup challenge: \(signupChallenge)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let signupChallenge = try await Auth0
        .authentication()
        .passkeySignupChallenge(email: "support@auth0.com",
                                name: "John Appleseed",
                                connection: "Username-Password-Authentication")
        .start()
    print("Obtained signup challenge: \(signupChallenge)")
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
    .passkeySignupChallenge(email: "support@auth0.com",
                            name: "John Appleseed",
                            connection: "Username-Password-Authentication")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { signupChallenge in
        print("Obtained signup challenge: \(signupChallenge)")
    })
    .store(in: &cancellables)
```
</details>

#### 2. Create a new passkey credential

Use the signup challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider) from the `AuthenticationServices` framework to generate a new passkey credential. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Register-a-new-account-on-a-service) to learn more.

```swift
let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: signupChallenge.relyingPartyId
)

let request = credentialProvider.createCredentialRegistrationRequest(
    challenge: signupChallenge.challengeData,
    name: signupChallenge.userName,
    userID: signupChallenge.userId
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
    case let signupPasskey as ASAuthorizationPlatformPublicKeyCredentialRegistration:
        // ...
    default:
        print("Unrecognized credential: \(authorization.credential)")
    }

    // ...
}
```

#### 3. Log the new user in

Use the created passkey credential and the signup challenge to log the new user in. This completes the signup process.

```swift
Auth0
    .authentication()
    .login(passkey: signupPasskey,
           challenge: signupChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
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
        .login(passkey: signupPasskey,
               challenge: signupChallenge,
               connection: "Username-Password-Authentication",
               scope: "openid profile email offline_access")
        .start()
    print("Obtained credentials: \(credentials)")
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
    .login(passkey: signupPasskey,
           challenge: signupChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>
