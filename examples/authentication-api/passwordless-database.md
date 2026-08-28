### Passwordless login with a database connection [EA]

> [!IMPORTANT]
> Passwordless login for database connections is currently in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

This flow lets users authenticate with a one-time code sent over email or SMS/voice against a **database connection** that has `email_otp` or `phone_otp` enabled. It is distinct from the `/passwordless/start` flow above, which uses dedicated passwordless connections.

#### 1. Issue an OTP challenge

Send a one-time code to the user's email. For privacy, the server **always responds successfully regardless of whether the user exists**. On success, save the returned `PasswordlessChallenge` for step 2.

To send the code via SMS or voice instead, use `passwordlessChallenge(phoneNumber:deliveryMethod:)` against a connection with `phone_otp` enabled.

Both methods accept an optional `allowSignup` parameter (defaults to `false`) that controls whether a new user is created if one does not yet exist.

#### 2. Verify the code and log in

Pass the `PasswordlessChallenge` from step 1 together with the code the user received to exchange for `Credentials`. If DPoP is enabled, a DPoP proof is attached automatically to this token request.

**Step 1 — issue the challenge:**

```swift
// Keep this reference until the user enters the code
var passwordlessChallenge: PasswordlessChallenge?

Auth0
    .authentication()
    .passwordlessChallenge(email: "user@example.com",
                           connection: "your-db-connection") // defaults to "Username-Password-Authentication"
    .start { result in
        switch result {
        case .success(let challenge):
            passwordlessChallenge = challenge
            // Prompt the user for the OTP they received
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

**Step 2 — verify the OTP:**

```swift
guard let challenge = passwordlessChallenge else { return }

Auth0
    .authentication()
    .login(otp: userEnteredOTP, challenge: challenge)
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
    // Step 1: issue the challenge and keep it
    let challenge = try await Auth0
        .authentication()
        .passwordlessChallenge(email: "user@example.com",
                               connection: "your-db-connection") // defaults to "Username-Password-Authentication"
        .start()
    // Step 2: once the user enters the code, pass the saved challenge back to log in
    let credentials = try await Auth0
        .authentication()
        .login(otp: userEnteredOTP, challenge: challenge)
        .start()
    print("Obtained credentials")
} catch {
    print("Failed with: \(error)")
}
```

</details>

> [!NOTE]
> The default scope used is `openid profile email`. Regardless of the scopes set to the request, the `openid` scope is always enforced.
