### Sign up with passkey and identifier verification

When your database connection requires the user's email address or phone number to be verified, Auth0 sends a one-time code (OTP) to each identifier that needs verification as part of the [passkey signup](signup-passkey.md) flow. The user must enter those codes before the passkey signup can be completed.

The flow is the same as a regular passkey signup, with two additions:

1. The signup challenge lists the identifiers that need verification in `verificationRequired`.
2. The collected codes are sent along with the passkey credential in the `verification` parameter.

> [!NOTE]
> The prerequisites are the same as for a [regular passkey signup](signup-passkey.md#prerequisites).

#### 1. Request a signup challenge

Request the signup challenge as usual. When verifying a phone number, you can use the `deliveryMethod` parameter to choose whether the code is sent by text message (`.text`) or voice call (`.voice`). If you don't set it, the server default applies.

```swift
Auth0
    .authentication()
    .passkeySignupChallenge(email: "support@auth0.com",
                            phoneNumber: "+14155552671",
                            connection: "Username-Password-Authentication",
                            deliveryMethod: .text)
    .start { result in
        switch result {
        case .success(let signupChallenge):
            // e.g. [.email, .phone]
            let methods = signupChallenge.verificationRequired ?? []
            print("Identifiers to verify: \(methods)")
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
                                phoneNumber: "+14155552671",
                                connection: "Username-Password-Authentication",
                                deliveryMethod: .text)
        .start()
    // e.g. [.email, .phone]
    let methods = signupChallenge.verificationRequired ?? []
    print("Identifiers to verify: \(methods)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

`verificationRequired` is an array of `PasskeyVerificationMethod` values:

| Value | Meaning |
|:------|:--------|
| `.email` | A code was sent to the user's email address. |
| `.phone` | A code was sent to the user's phone number. |
| `.unknown(String)` | An identifier type that this version of the SDK doesn't recognize. The associated value is the raw value returned by Auth0. |

If `verificationRequired` is `nil` or empty, no verification is needed. Continue with the [regular passkey signup](signup-passkey.md#2-create-a-new-passkey-credential).

#### 2. Collect the verification codes

Prompt the user for the code sent to each identifier in `verificationRequired`. Store the codes in a dictionary, using each method's `rawValue` as the key.

```swift
var verification: [String: String] = [:]

for method in signupChallenge.verificationRequired ?? [] {
    // Prompt the user for the code sent to this identifier
    verification[method.rawValue] = await promptForCode(method)
}

// e.g. ["email": "123456", "phone": "654321"]
```

> [!TIP]
> Collect the codes **before** creating the passkey credential. That way the user doesn't create a passkey on their device for a signup that never completes.

To resend a code (for example, when the user taps "Resend code"), request a new signup challenge with the **same** `email`, `phoneNumber`, and `deliveryMethod` values. Auth0 sends fresh codes and returns a new challenge. Discard the previous challenge and any codes already collected, and use the new challenge from then on.

#### 3. Create a new passkey credential

Create the passkey credential from the signup challenge, exactly as in a [regular passkey signup](signup-passkey.md#2-create-a-new-passkey-credential).

#### 4. Log the new user in

Pass the passkey credential, the signup challenge, and the collected codes to `login(passkey:challenge:connection:audience:scope:organization:verification:)`.

```swift
Auth0
    .authentication()
    .login(passkey: signupPasskey,
           challenge: signupChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access",
           verification: verification)
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
        .login(passkey: signupPasskey,
               challenge: signupChallenge,
               connection: "Username-Password-Authentication",
               scope: "openid profile email offline_access",
               verification: verification)
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
    .login(passkey: signupPasskey,
           challenge: signupChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access",
           verification: verification)
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

> [!NOTE]
> If `verification` is empty, the SDK doesn't send a `verification` object at all.

#### 5. Handle verification errors

If the login request fails, use these `AuthenticationError` properties to decide what to do next:

| Error | Condition | What to do |
|:------|:----------|:-----------|
| Wrong code, retryable | `isPasskeyVerificationRetryable` is `true` | Ask the user again for the codes of the identifiers listed in `passkeyVerificationRequired`. Retry with the **same** passkey credential, using a challenge that carries `passkeyAuthSession`. |
| Missing code | `code == "invalid_request"` | A code for a required identifier wasn't sent. Retry with the same challenge and passkey credential, and include the missing code. |
| Session no longer valid | `code == "invalid_grant"` and `isPasskeyVerificationRetryable` is `false` | The session is expired, used up, or has run out of attempts. Request a new signup challenge and start over. |

```swift
do {
    let credentials = try await Auth0
        .authentication()
        .login(passkey: signupPasskey,
               challenge: signupChallenge,
               connection: "Username-Password-Authentication",
               scope: "openid profile email offline_access",
               verification: verification)
        .start()
    print("Obtained credentials")
} catch let error as AuthenticationError where error.isPasskeyVerificationRetryable {
    // One or more codes were wrong, but the session is still alive
    let methodsToRetry = error.passkeyVerificationRequired ?? []
    print("Wrong code for: \(methodsToRetry)")

    if let authSession = error.passkeyAuthSession {
        // Reuse the original challenge data with the session returned by Auth0
        signupChallenge = PasskeySignupChallenge(authenticationSession: authSession,
                                                 relyingPartyId: signupChallenge.relyingPartyId,
                                                 userId: signupChallenge.userId,
                                                 userName: signupChallenge.userName,
                                                 challengeData: signupChallenge.challengeData,
                                                 verificationRequired: methodsToRetry)
    }

    // Ask the user again for the codes of `methodsToRetry` only, then retry the login request
    // with the same `signupPasskey`
} catch let error as AuthenticationError where error.code == "invalid_request" {
    // A required code is missing; include it and retry with the same challenge and passkey credential
    print("Failed with: \(error)")
} catch let error as AuthenticationError where error.code == "invalid_grant" {
    // The session is no longer valid; request a new signup challenge and start over
    print("Failed with: \(error)")
} catch {
    print("Failed with: \(error)")
}
```

<details>
  <summary>Using completion handlers</summary>

```swift
Auth0
    .authentication()
    .login(passkey: signupPasskey,
           challenge: signupChallenge,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access",
           verification: verification)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials")
        case .failure(let error) where error.isPasskeyVerificationRetryable:
            // One or more codes were wrong, but the session is still alive
            let methodsToRetry = error.passkeyVerificationRequired ?? []
            print("Wrong code for: \(methodsToRetry)")
            // Update the challenge with `error.passkeyAuthSession`, ask the user again for the codes
            // of `methodsToRetry` only, and retry the login request with the same `signupPasskey`
        case .failure(let error) where error.code == "invalid_request":
            // A required code is missing; include it and retry with the same challenge and passkey credential
            print("Failed with: \(error)")
        case .failure(let error):
            // e.g. the session is no longer valid; request a new signup challenge and start over
            print("Failed with: \(error)")
        }
    }
```
</details>

> [!IMPORTANT]
> When retrying after a wrong code, don't create a new passkey credential. Reuse the one from the first attempt. You only need a new passkey credential when you request a new signup challenge, because its challenge data is different.
