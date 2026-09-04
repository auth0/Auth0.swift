### Log in with passkey

Logging a user in with a passkey is a three-step process. First, you request a login challenge from Auth0. Then, you pass that challenge to Apple's [`AuthenticationServices`](https://developer.apple.com/documentation/authenticationservices) APIs to request an **existing passkey credential**. Finally, you use the resulting passkey credential and the original challenge to log the user in.

#### Prerequisites

- A deployment target of iOS 16.6+, macOS 13.5+, or visionOS 1.0+ (the passkey APIs are unavailable on older versions).
- A custom domain configured for your Auth0 tenant.
- The **Passkeys** grant to be enabled for your Auth0 application.
- The iOS **Device Settings** configured for your Auth0 application.

Check [our documentation](https://auth0.com/docs/native-passkeys-for-mobile-applications#before-you-begin) for more information.

#### 1. Request a login challenge

If a database connection name is not specified, your tenant's default directory will be used.

```swift
Auth0
    .authentication()
    .passkeyLoginChallenge(connection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let loginChallenge):
            print("Obtained login challenge: \(loginChallenge)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let loginChallenge = try await Auth0
        .authentication()
        .passkeyLoginChallenge(connection: "Username-Password-Authentication")
        .start()
    print("Obtained login challenge: \(loginChallenge)")
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
    .passkeyLoginChallenge(connection: "Username-Password-Authentication")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { loginChallenge in
        print("Obtained login challenge: \(loginChallenge)")
    })
    .store(in: &cancellables)
```
</details>

#### 2. Request an existing passkey credential

Use the login challenge with [`ASAuthorizationPlatformPublicKeyCredentialProvider`](https://developer.apple.com/documentation/authenticationservices/asauthorizationplatformpublickeycredentialprovider) from the `AuthenticationServices` framework to request an existing passkey credential. Check out [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/supporting-passkeys#Connect-to-a-service-with-an-existing-account) to learn more.

```swift
let credentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: loginChallenge.relyingPartyId
)

let request = credentialProvider.createCredentialAssertionRequest(
    challenge: loginChallenge.challengeData
)

let authController = ASAuthorizationController(authorizationRequests: [request])
authController.delegate = self // ASAuthorizationControllerDelegate
authController.presentationContextProvider = self
authController.performRequests()
```

The resulting passkey credential will be delivered through the [`ASAuthorizationControllerDelegate`](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontrollerdelegate) delegate.

```swift
func authorizationController(controller: ASAuthorizationController,
                             didCompleteWithAuthorization authorization: ASAuthorization) {
    switch authorization.credential {
    case let loginPasskey as ASAuthorizationPlatformPublicKeyCredentialAssertion:
        // ...
    default:
        print("Unrecognized credential: \(authorization.credential)")
    }

    // ...
}
```

#### 3. Log the user in

Use the resulting passkey credential and the login challenge to log the user in.

```swift
Auth0
    .authentication()
    .login(passkey: loginPasskey,
           challenge: loginChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
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
        .login(passkey: loginPasskey,
               challenge: loginChallenge,
               connection: "Username-Password-Authentication",
               scope: "openid profile email offline_access")
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
    .login(passkey: loginPasskey,
           challenge: loginChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access")
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
