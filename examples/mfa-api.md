## MFA API (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/mfaclient)**

- [Prerequisites](#prerequisites)
- [Handling MFA required errors](#handling-mfa-required-errors)
- [Get available authenticators](#get-available-authenticators)
- [Enroll MFA factors](#enroll-mfa-factors)
  - [Enroll SMS](#enroll-sms)
  - [Enroll email](#enroll-email)
  - [Enroll OTP (TOTP)](#enroll-otp-totp)
  - [Enroll push notification](#enroll-push-notification)
- [Challenge an enrolled authenticator](#challenge-an-enrolled-authenticator)
- [Verify MFA](#verify-mfa)
  - [Verify with OOB code](#verify-with-oob-code)
  - [Verify with OTP code](#verify-with-otp-code)
  - [Verify with recovery code](#verify-with-recovery-code)
- [Complete MFA flow examples](#complete-mfa-flow-examples)
- [MFA client configuration](#mfa-client-configuration)
- [MFA client errors](#mfa-client-errors)

The MFA API allows you to implement multi-factor authentication flows using the Auth0 Authentication API. This includes enrolling MFA factors, challenging enrolled factors, and verifying MFA codes.

> [!NOTE]
> The MFA API requires specific grant types to be enabled in your Auth0 application. Check the [Dashboard](https://manage.auth0.com/#/applications/) under **Application Settings > Advanced Settings > Grant Types**.

### Prerequisites

To use the MFA API, you need to:

1. Enable the appropriate **MFA** grant type for your Auth0 application

2. Enable the MFA factors you want to use in the [Auth0 Dashboard](https://manage.auth0.com/#/security/mfa) under **Security > Multi-factor Auth**.

3. For SMS, email, or push notification factors, configure the appropriate providers in your Auth0 tenant.

### Handling MFA required errors

When a user attempts to log in and MFA is required, you'll receive an `AuthenticationError` with the `isMultifactorRequired` property set to `true`. This error contains an MFA token that you'll need for subsequent MFA operations.

The error payload includes two fields:
- **`enroll`**: Available when the user needs to enroll a new MFA factor. Contains the types of factors they can enroll.
- **`challenge`**: Available when the user has already enrolled MFA factors. Contains the types of factors available to challenge.

```swift
Auth0
    .authentication()
    .login(usernameOrEmail: "support@auth0.com",
           password: "secret-password",
           realmOrConnection: "Username-Password-Authentication",
           scope: "openid profile email")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials")
        case .failure(let error) where error.isMultifactorRequired:
            // MFA is required
            if let mfaPayload = error.mfaRequiredErrorPayload {
                let mfaToken = mfaPayload.mfaToken
                print("Received MFA token")

                // Check if enrollment is required
                if let enrollTypes = mfaPayload.mfaRequirements.enroll {
                    print("User needs to enroll MFA")
                    print("Available enrollment types: \(enrollTypes.map { $0.type })")
                    // Example output: ["otp", "phone", "push-notification"]
                    // Proceed with MFA enrollment using one of these types
                }

                // Check if challenge is available (user already enrolled)
                if let challengeTypes = mfaPayload.mfaRequirements.challenge {
                    print("User has enrolled MFA factors")
                    print("Available challenge types: \(challengeTypes.map { $0.type })")
                    // Example output: ["otp", "phone"]
                    // Get authenticators and challenge one of them
                }
            }
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
        .login(usernameOrEmail: "support@auth0.com",
               password: "secret-password",
               realmOrConnection: "Username-Password-Authentication",
               scope: "openid profile email")
        .start()
    print("Obtained credentials")
} catch let error as AuthenticationError where error.isMultifactorRequired {
    // MFA is required
    if let mfaPayload = error.mfaRequiredErrorPayload {
        let mfaToken = mfaPayload.mfaToken
        print("Received MFA token")

        // Check if enrollment is required
        if let enrollTypes = mfaPayload.mfaRequirements.enroll {
            print("User needs to enroll MFA")
            print("Available enrollment types: \(enrollTypes.map { $0.type })")
            // Example output: ["otp", "phone", "push-notification"]
        }

        // Check if challenge is available (user already enrolled)
        if let challengeTypes = mfaPayload.mfaRequirements.challenge {
            print("User has enrolled MFA factors")
            print("Available challenge types: \(challengeTypes.map { $0.type })")
            // Example output: ["otp", "phone"]
        }
    }
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
    .login(usernameOrEmail: "support@auth0.com",
           password: "secret-password",
           realmOrConnection: "Username-Password-Authentication",
           scope: "openid profile email")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error as AuthenticationError) = completion,
           error.isMultifactorRequired,
           let mfaPayload = error.mfaRequiredErrorPayload {
            let mfaToken = mfaPayload.mfaToken
            print("Received MFA token")

            if let enrollTypes = mfaPayload.mfaRequirements.enroll {
                print("User needs to enroll MFA")
                print("Available enrollment types: \(enrollTypes.map { $0.type })")
                // Example output: ["otp", "phone", "push-notification"]
            }

            if let challengeTypes = mfaPayload.mfaRequirements.challenge {
                print("User has enrolled MFA factors")
                print("Available challenge types: \(challengeTypes.map { $0.type })")
                // Example output: ["otp", "phone"]
            }
        }
    }, receiveValue: { credentials in
        print("Obtained credentials")
    })
    .store(in: &cancellables)
```
</details>

### Get available authenticators

After receiving an MFA token, you can retrieve the list of available authenticators that the user has already enrolled. Use the factors from the `challenge` field of the MFA required error payload to filter the authenticators.

> [!NOTE]
> If the `challenge` list is empty the user has no enrolled factors, so direct them to [enrollment](#enroll-mfa-factors) instead. Calling `getAuthenticators` with an empty `factorsAllowed` fails with `invalid_request`.

```swift
// Extract factors from the challenge field of MFA required error payload
let factorsAllowed = mfaPayload.mfaRequirements.challenge?.map { $0.type } ?? []

Auth0
    .mfa()
    .getAuthenticators(mfaToken: mfaToken, factorsAllowed: factorsAllowed)
    .start { result in
        switch result {
        case .success(let authenticators):
            print("Available authenticators: \(authenticators)")
            for authenticator in authenticators {
                print("ID: \(authenticator.id), Type: \(authenticator.authenticatorType)")
            }
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
// Extract factors from the challenge field of MFA required error payload
let factorsAllowed = mfaPayload.mfaRequirements.challenge?.map { $0.type } ?? []

do {
    let authenticators = try await Auth0
        .mfa()
        .getAuthenticators(mfaToken: mfaToken, factorsAllowed: factorsAllowed)
        .start()
    print("Available authenticators: \(authenticators)")
    for authenticator in authenticators {
        print("ID: \(authenticator.id), Type: \(authenticator.authenticatorType)")
    }
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
// Extract factors from the challenge field of MFA required error payload
let factorsAllowed = mfaPayload.mfaRequirements.challenge?.map { $0.type } ?? []

Auth0
    .mfa()
    .getAuthenticators(mfaToken: mfaToken, factorsAllowed: factorsAllowed)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { authenticators in
        print("Available authenticators: \(authenticators)")
        for authenticator in authenticators {
            print("ID: \(authenticator.id), Type: \(authenticator.authenticatorType)")
        }
    })
    .store(in: &cancellables)
```
</details>

### Enroll MFA factors

When MFA enrollment is required, you can enroll various types of MFA factors.

#### Enroll SMS

Enroll a phone number for SMS-based MFA. An SMS with a verification code will be sent to the phone number.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
    .start { result in
        switch result {
        case .success(let challenge):
            print("SMS enrollment initiated")
            print("Received OOB challenge")
            // Now prompt user for the code they received via SMS
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let challenge = try await Auth0
        .mfa()
        .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
        .start()
    print("SMS enrollment initiated")
    print("Received OOB challenge")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("SMS enrollment initiated")
        print("Received OOB challenge")
    })
    .store(in: &cancellables)
```
</details>

#### Enroll email

Enroll an email address for email-based MFA. A verification code will be sent to the email address.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, email: "user@example.com")
    .start { result in
        switch result {
        case .success(let challenge):
            print("Email enrollment initiated")
            print("Received OOB challenge")
            // Now prompt user for the code they received via email
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let challenge = try await Auth0
        .mfa()
        .enroll(mfaToken: mfaToken, email: "user@example.com")
        .start()
    print("Email enrollment initiated")
    print("Received OOB challenge")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, email: "user@example.com")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("Email enrollment initiated")
        print("Received OOB challenge")
    })
    .store(in: &cancellables)
```
</details>

#### Enroll OTP (TOTP)

Enroll a time-based one-time password (TOTP) authenticator. This returns a QR code and secret that can be scanned by authenticator apps like Google Authenticator or Authy.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let challenge):
            print("OTP enrollment initiated")
            if let barcodeUri = challenge.barcodeUri {
                print("QR Code URI: \(barcodeUri)")
                // Display this as a QR code for the user to scan
            }
            if let secret = challenge.secret {
                print("TOTP secret generated")
                // User can manually enter this into their authenticator app
            }
            // After user scans QR code and sets up authenticator app,
            // prompt them for the OTP code to complete enrollment
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let challenge = try await Auth0
        .mfa()
        .enroll(mfaToken: mfaToken)
        .start()
    print("OTP enrollment initiated")
    if let barcodeUri = challenge.barcodeUri {
        print("QR Code URI: \(barcodeUri)")
    }
    if let secret = challenge.secret {
        print("TOTP secret generated")
    }
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("OTP enrollment initiated")
        if let barcodeUri = challenge.barcodeUri {
            print("QR Code URI: \(barcodeUri)")
        }
        if let secret = challenge.secret {
            print("TOTP secret generated")
        }
    })
    .store(in: &cancellables)
```
</details>

#### Enroll push notification

Enroll Auth0 Guardian push notifications as an MFA factor.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let challenge):
            print("Push notification enrollment initiated")
            if let barcodeUri = challenge.barcodeUri {
                print("QR Code URI: \(barcodeUri)")
                // Display this as a QR code for the user to scan with Guardian app
            }
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let challenge = try await Auth0
        .mfa()
        .enroll(mfaToken: mfaToken)
        .start()
    print("Push notification enrollment initiated")
    if let barcodeUri = challenge.barcodeUri {
        print("QR Code URI: \(barcodeUri)")
    }
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("Push notification enrollment initiated")
        if let barcodeUri = challenge.barcodeUri {
            print("QR Code URI: \(barcodeUri)")
        }
    })
    .store(in: &cancellables)
```
</details>

### Challenge an enrolled authenticator

For already enrolled MFA factors, you can request a challenge to be sent to the user.

```swift
Auth0
    .mfa()
    .challenge(with: "sms|dev_authenticator_id", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let challenge):
            print("Challenge sent")
            print("Challenge type: \(challenge.challengeType)")
            if let oobCode = challenge.oobCode {
                print("Received OOB challenge")
            }
            // Now prompt user for the verification code they received
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let challenge = try await Auth0
        .mfa()
        .challenge(with: "sms|dev_authenticator_id", mfaToken: mfaToken)
        .start()
    print("Challenge sent")
    print("Challenge type: \(challenge.challengeType)")
    if let oobCode = challenge.oobCode {
        print("Received OOB challenge")
    }
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .mfa()
    .challenge(with: "sms|dev_authenticator_id", mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("Challenge sent")
        print("Challenge type: \(challenge.challengeType)")
        if let oobCode = challenge.oobCode {
            print("Received OOB challenge")
        }
    })
    .store(in: &cancellables)
```
</details>

### Verify MFA

After enrolling or challenging an MFA factor, you need to verify the code to complete authentication.

#### Verify with OOB code

Verify an out-of-band (OOB) code received via SMS or email.

```swift
Auth0
    .mfa()
    .verify(oobCode: "123456", bindingCode: nil, mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
            print("Obtained credentials")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

With a binding code for enhanced security:

```swift
Auth0
    .mfa()
    .verify(oobCode: "oob_code_value", bindingCode: "BINDING_CODE", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
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
        .mfa()
        .verify(oobCode: "123456", bindingCode: nil, mfaToken: mfaToken)
        .start()
    print("MFA verification successful!")
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
    .mfa()
    .verify(oobCode: "123456", bindingCode: nil, mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("MFA verification successful!")
        print("Obtained credentials")
    })
    .store(in: &cancellables)
```
</details>

#### Verify with OTP code

Verify a one-time password (OTP) code from an authenticator app.

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
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
        .mfa()
        .verify(otp: "123456", mfaToken: mfaToken)
        .start()
    print("MFA verification successful!")
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
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("MFA verification successful!")
        print("Obtained credentials")
    })
    .store(in: &cancellables)
```
</details>

#### Verify with recovery code

Verify using a recovery code when the primary MFA factor is unavailable.

```swift
Auth0
    .mfa()
    .verify(recoveryCode: "RECOVERY_CODE_123", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
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
        .mfa()
        .verify(recoveryCode: "RECOVERY_CODE_123", mfaToken: mfaToken)
        .start()
    print("MFA verification successful!")
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
    .mfa()
    .verify(recoveryCode: "RECOVERY_CODE_123", mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("MFA verification successful!")
        print("Obtained credentials")
    })
    .store(in: &cancellables)
```
</details>

### Complete MFA flow examples

#### Complete SMS enrollment and verification flow

```swift
// Step 1: Initial login attempt
Auth0
    .authentication()
    .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Login successful")

        case .failure(let error) where error.isMultifactorRequired:
            guard let mfaToken = error.mfaRequiredErrorPayload?.mfaToken else { return }

            // Step 2: Enroll SMS
            Auth0
                .mfa()
                .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
                .start { enrollResult in
                    switch enrollResult {
                    case .success(let challenge):
                        print("SMS challenge sent")

                        // Step 3: User enters the code they received via SMS
                        let userEnteredCode = "123456" // Get this from user input

                        // Step 4: Verify the OOB code
                        Auth0
                            .mfa()
                            .verify(oobCode: challenge.oobCode, bindingCode: userEnteredCode, mfaToken: mfaToken)
                            .start { verifyResult in
                                switch verifyResult {
                                case .success(let credentials):
                                    print("MFA enrollment complete! Credentials: \(credentials)")
                                case .failure(let error):
                                    print("Verification failed: \(error)")
                                }
                            }

                    case .failure(let error):
                        print("Enrollment failed: \(error)")
                    }
                }

        case .failure(let error):
            print("Login failed: \(error)")
        }
    }
```

#### Complete OTP enrollment and verification flow

```swift
// Step 1: Initial login attempt
Auth0
    .authentication()
    .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Login successful")

        case .failure(let error) where error.isMultifactorRequired:
            guard let mfaToken = error.mfaRequiredErrorPayload?.mfaToken else { return }

            // Step 2: Enroll OTP authenticator
            Auth0
                .mfa()
                .enroll(mfaToken: mfaToken)
                .start { enrollResult in
                    switch enrollResult {
                    case .success(let challenge):
                        // Step 3: Display QR code to user
                        if let barcodeUri = challenge.barcodeUri {
                            print("Show this QR code to user: \(barcodeUri)")
                            // Generate and display QR code from this URI
                        }
                        if let secret = challenge.secret {
                            print("Manual entry code generated")
                        }

                        // Step 4: User scans QR code and enters OTP from their app
                        let userEnteredOtp = "123456" // Get this from user input

                        // Step 5: Verify the OTP code
                        Auth0
                            .mfa()
                            .verify(otp: userEnteredOtp, mfaToken: mfaToken)
                            .start { verifyResult in
                                switch verifyResult {
                                case .success(let credentials):
                                    print("MFA enrollment complete! Credentials: \(credentials)")
                                case .failure(let error):
                                    print("Verification failed: \(error)")
                                }
                            }

                    case .failure(let error):
                        print("Enrollment failed: \(error)")
                    }
                }

        case .failure(let error):
            print("Login failed: \(error)")
        }
    }
```

#### Challenge existing MFA factor flow

```swift
// Step 1: Initial login attempt
Auth0
    .authentication()
    .login(usernameOrEmail: email, password: password, realmOrConnection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Login successful")

        case .failure(let error) where error.isMultifactorRequired:
            guard let mfaPayload = error.mfaRequiredErrorPayload else { return }
            let mfaToken = mfaPayload.mfaToken

            // Step 2: Extract factors from the challenge field
            let factorsAllowed = mfaPayload.mfaRequirements.challenge?.map { $0.type } ?? []

            // Step 3: Get available authenticators
            Auth0
                .mfa()
                .getAuthenticators(mfaToken: mfaToken, factorsAllowed: factorsAllowed)
                .start { authResult in
                    switch authResult {
                    case .success(let authenticators):
                        guard let authenticator = authenticators.first else { return }

                        // Step 4: Challenge the authenticator
                        Auth0
                            .mfa()
                            .challenge(with: authenticator.id, mfaToken: mfaToken)
                            .start { challengeResult in
                                switch challengeResult {
                                case .success(let challenge):
                                    print("Challenge sent: \(challenge)")

                                    // Step 5: User enters the code
                                    let userEnteredCode = "123456" // Get from user input

                                    // Step 6: Verify based on challenge type
                                    if challenge.challengeType == "oob" {
                                        Auth0
                                            .mfa()
                                            .verify(oobCode: challenge.oobCode, bindingCode: userEnteredCode, mfaToken: mfaToken)
                                            .start { print($0) }
                                    } else if challenge.challengeType == "otp" {
                                        Auth0
                                            .mfa()
                                            .verify(otp: userEnteredCode, mfaToken: mfaToken)
                                            .start { print($0) }
                                    }

                                case .failure(let error):
                                    print("Challenge failed: \(error)")
                                }
                            }

                    case .failure(let error):
                        print("Failed to get authenticators: \(error)")
                    }
                }

        case .failure(let error):
            print("Login failed: \(error)")
        }
    }
```

### MFA client configuration

#### Add custom parameters

Use the `parameters()` method to add custom parameters to any request.

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken) // Any request
    .parameters(["key": "value"])
    // ...
```

#### Add custom headers

Use the `headers()` method to add custom headers to any request.

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken) // Any request
    .headers(["key": "value"])
    // ...
```

#### Use a custom `URLSession` instance

You can specify a custom `URLSession` instance for more advanced networking configuration, such as customizing timeout values.

```swift
Auth0
    .mfa(session: customURLSession)
    // ...
```

### MFA client errors

The MFA client produces specific error types for different operations, all conforming to the `Auth0APIError` protocol:

- **`MfaListAuthenticatorsError`**: Returned by `getAuthenticators()` when listing authenticators fails
- **`MfaEnrollmentError`**: Returned by all `enroll()` methods when enrollment fails
- **`MfaChallengeError`**: Returned by `challenge()` when initiating a challenge fails
- **`MFAVerifyError`**: Returned by all `verify()` methods when verification fails

All MFA error types provide:
- `code`: The error code from the API response
- `statusCode`: The HTTP status code
- `info`: Raw error information dictionary
- `localizedDescription`: A human-readable error description (inherited from `LocalizedError`)
- `debugDescription`: A detailed description for debugging purposes
- `cause`: The underlying `Error` value, if any (useful for network errors)
- `isNetworkError`: Whether the request failed due to network issues
- `isRetryable`: Whether the error is retryable (network errors, rate limiting, or server errors)

#### Example error handling

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Success: \(credentials)")
        case .failure(let error):
            print("Failed with code: \(error.code)")
            print("Description: \(error.localizedDescription)")
            print("Status code: \(error.statusCode)")
        }
    }
```

#### Common error codes

Each MFA error type provides specific error codes to help you handle different scenarios:

**MfaListAuthenticatorsError** (from `getAuthenticators()`):
- `invalid_request`: Request parameters are invalid (e.g., missing or empty factorsAllowed)
- `invalid_token`: MFA token is invalid or expired
- `access_denied`: User lacks permission to access this resource

**MfaEnrollmentError** (from `enroll()` methods):
- `invalid_request`: Enrollment parameters are invalid
- `invalid_token`: MFA token is invalid or expired
- `enrollment_conflict`: Authenticator is already enrolled
- `unsupported_challenge_type`: Requested factor type is not enabled

**MfaChallengeError** (from `challenge()`):
- `invalid_request`: Challenge parameters are invalid
- `invalid_token`: MFA token is invalid or expired
- `authenticator_not_found`: Specified authenticator doesn't exist
- `unsupported_challenge_type`: Authenticator type doesn't support challenges

**MFAVerifyError** (from `verify()` methods):
- `invalid_grant`: Verification code is incorrect or expired
- `invalid_token`: MFA token is invalid or expired
- `invalid_oob_code`: Out-of-band code is invalid
- `invalid_binding_code`: Binding code (SMS/email code) is incorrect
- `expired_token`: Verification code has expired

#### Handling specific error cases

You can check the `code` property to handle specific error scenarios:

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
    .start { result in
        switch result {
        case .success(let challenge):
            print("Enrollment successful")
        case .failure(let error):
            switch error.code {
            case "invalid_token":
                print("MFA token is invalid or expired")
            case "invalid_phone_number":
                print("Phone number format is invalid")
            case "unsupported_challenge_type":
                print("This MFA factor is not supported")
            default:
                print("Enrollment failed: \(error.localizedDescription)")
            }
        }
    }
```

#### Network and retryable errors

MFA errors inherit `isNetworkError` and `isRetryable` properties from `Auth0APIError` to help handle transient failures:

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Success: \(credentials)")
        case .failure(let error):
            if error.isNetworkError {
                print("Network connectivity issue - check your connection")
            } else if error.isRetryable {
                print("Request can be retried (rate limiting or server error)")
            } else {
                print("Permanent error: \(error.localizedDescription)")
            }
        }
    }
```

The `isNetworkError` property returns `true` for network-related failures such as:
- No internet connection
- DNS lookup failures
- Connection timeouts
- Data not allowed

The `isRetryable` property returns `true` for errors that can be retried:
- Network errors (as determined by `isNetworkError`)
- Rate limiting errors (HTTP 429)
- Server errors (HTTP 5xx)

#### Authentication flow errors

When handling MFA-required errors from the authentication flow (not the MFA client), you'll still receive `AuthenticationError` values. Use these properties to identify MFA-related scenarios:

- `isMultifactorRequired`: MFA is required to authenticate
- `isMultifactorEnrollRequired`: MFA is required and the user is not enrolled
- `isMultifactorCodeInvalid`: The MFA code sent is invalid or expired (legacy)
- `isMultifactorTokenInvalid`: The MFA token is invalid or expired (legacy)

```swift
Auth0
    .authentication()
    .login(usernameOrEmail: "user@example.com", password: "password", realmOrConnection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Success: \(credentials)")
        case .failure(let error) where error.isMultifactorRequired:
            print("MFA is required")
            // Extract mfaToken and proceed with MFA flow
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

Check the [Auth0APIError API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/auth0apierror) and [AuthenticationError API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/authenticationerror) to learn more about error handling.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Use the error `code` property and error types instead, which are part of the API.

[Go up ⤴](../EXAMPLES.md#examples)
