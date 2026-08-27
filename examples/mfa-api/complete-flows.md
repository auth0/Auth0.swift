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
            print("Login successful: \(credentials)")

        case .failure(let error) where error.isMultifactorRequired:
            guard let mfaToken = error.mfaRequiredErrorPayload?.mfaToken else { return }

            // Step 2: Enroll SMS
            Auth0
                .mfa()
                .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
                .start { enrollResult in
                    switch enrollResult {
                    case .success(let challenge):
                        print("SMS sent with OOB code: \(challenge.oobCode)")

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
            print("Login successful: \(credentials)")

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
                            print("Or manual entry code: \(secret)")
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
            print("Login successful: \(credentials)")

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
