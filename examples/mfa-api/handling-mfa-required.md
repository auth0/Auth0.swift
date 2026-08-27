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
            print("Obtained credentials: \(credentials)")
        case .failure(let error) where error.isMultifactorRequired:
            // MFA is required
            if let mfaPayload = error.mfaRequiredErrorPayload {
                let mfaToken = mfaPayload.mfaToken
                print("MFA token: \(mfaToken)")

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
    print("Obtained credentials: \(credentials)")
} catch let error as AuthenticationError where error.isMultifactorRequired {
    // MFA is required
    if let mfaPayload = error.mfaRequiredErrorPayload {
        let mfaToken = mfaPayload.mfaToken
        print("MFA token: \(mfaToken)")

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
            print("MFA token: \(mfaToken)")

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
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>
