## My Account API (iOS / macOS / tvOS / watchOS / visionOS) [EA]

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/myaccount)**

- [Enroll a new passkey](#enroll-a-new-passkey)
- [Enroll a new email](#enroll-a-new-email-authentication-method)
- [Enroll a new phone](#enroll-a-new-phone-authentication-method)
- [Enroll a new totp](#enroll-a-new-totp-authentication-method)
- [Enroll a new push notification](#enroll-a-new-push-notification-authentication-method)
- [Enroll a new recovery code](#enroll-a-new-recovery-code-authentication-method)
- [Enroll a new password](#enroll-a-new-password-authentication-method)
- [Get all factors](#get-all-factors)
- [Get all authentication methods](#get-all-authentication-methods)
- [Get an authentication method by id](#get-an-authentication-method-by-id)
- [Delete an authentication method](#delete-an-authentication-method)
- [My Account API client errors](#my-account-api-client-errors)

> [!NOTE]
> The My Account API is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

Use the Auth0 My Account API to manage the current user's account.

To call the My Account API, you need an access token issued specifically for this API, including any required scopes for the operations you want to perform. See [API credentials [EA]](credentials-manager.md#api-credentials-ea) to learn how to obtain one.

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

### Enroll a new push notification authentication method

**Scopes required:** `create:me:authentication_methods`

Enrolling a new push notification authentication method is a two-step process. First, you request an enrollment challenge from Auth0. Then, you use the original challenge to enroll the push notification authentication method with Auth0.

#### Prerequisites

- Enable the MFA grant type for your application. Go to Auth0 Dashboard > Applications > Advanced Settings > Grant Types and select MFA.
- Enable the Push Notification factor. Go to Auth0 Dashboard > Security > Multi-factor Auth > Push Notification using Auth0 Guardian.
- The iOS **Device Settings** configured for your Auth0 application.

#### 1. Request an enrollment challenge

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .enrollPushNotification()
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
        .enrollPushNotification()
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
    .enrollPushNotification()
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

#### 2. Enroll the push notification authentication method

To confirm the enrollment, the end user will need to scan a QR code with the barcode_uri from enrollment challenge in the Guardian application, within the next 5 minutes and invoke confirmPushNotificationEnrollment method.

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .confirmPushNotificationEnrollment(id: id, 
                                       authSession: authSession)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Enrolled push notification: \(authenticationMethod)")
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
        .confirmPushNotificationEnrollment(id: id, 
                                           authSession: authSession)
        .start()
    print("Enrolled push notification: \(authenticationMethod)")
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
   .confirmPushNotificationEnrollment(id: id, 
                                      authSession: authSession)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Enrolled push notification: \(authenticationMethod)")
    })
    .store(in: &cancellables)
```
</details>

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

### Get all factors

**Scopes required:** `read:me:factors`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .getFactors()
    .start { result in
        switch result {
        case .success(let factors):
            print("Obtained factors: \(factors)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let factors = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .getFactors()
        .start()
    print("Obtained factors: \(factors)")
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
    .getFactors()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { factors in
        print("Obtained factors: \(factors)")
    })
    .store(in: &cancellables)
```
</details>

### Get all authentication methods

**Scopes required:** `read:me:authentication_methods`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .getAuthenticationMethods()
    .start { result in
        switch result {
        case .success(let authenticationMethods):
            print("Obtained authentication methods: \(authenticationMethods)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let authenticationMethods = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .getAuthenticationMethods()
        .start()
    print("Obtained authentication methods: \(authenticationMethods)")
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
    .getAuthenticationMethods()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethods in
        print("Obtained authentication methods: \(authenticationMethods)")
    })
    .store(in: &cancellables)
```
</details>

### Get an authentication method by id

**Scopes required:** `read:me:authentication_methods`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .getAuthenticationMethod(by: id)
    .start { result in
        switch result {
        case .success(let authenticationMethod):
            print("Obtained authentication method: \(authenticationMethod)")
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
        .getAuthenticationMethod(by: id)
        .start()
    print("Obtained authentication method: \(authenticationMethod)")
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
    .getAuthenticationMethod(by: id)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticationMethod in
        print("Obtained authentication method: \(authenticationMethod)")

    })
    .store(in: &cancellables)
```
</details>

### Delete an authentication method

**Scopes required:** `delete:me:authentication_methods`

```swift
Auth0
    .myAccount(token: apiCredentials.accessToken)
    .authenticationMethods
    .deleteAuthenticationMethod(by: id)
    .start { result in
        switch result {
        case .success:
            print("Authentication method is successfully deleted")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let _ = try await Auth0
        .myAccount(token: apiCredentials.accessToken)
        .authenticationMethods
        .deleteAuthenticationMethod(by: id)
        .start()
    print("Authentication method is successfully deleted")
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
    .deleteAuthenticationMethod(by: id)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { _ in
        print("Authentication method is successfully deleted")
    })
    .store(in: &cancellables)
```
</details>


### My Account API client errors

The My Account API client will only produce `MyAccountError` error values.

- The `info` property contains additional information about the error.
- The `cause` property contains the underlying error value, if any.
- Use the `isNetworkError` property to check if the request failed due to networking issues.
- Use the `isRetryable` property to check if the error represents a transient failure that can be retried (network errors, rate limiting, or server errors).

See the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/myaccounterror) to learn more about the available `MyAccountError` properties.

[Go up ⤴](../EXAMPLES.md#examples)
