### Sign up with passkey and identifier verification

When your database connection requires the user's email address or phone number to be verified, Auth0 sends a one-time code (OTP) to each identifier that needs verification as part of the [passkey signup](signup-passkey.md) flow. The user must enter those codes before the passkey signup can be completed.

The flow is the same as a regular passkey signup, with two additions:

1. The signup challenge lists the identifiers that need verification in `verificationRequired`.
2. The collected codes are sent along with the passkey credential in the `verification` parameter.

> [!NOTE]
> The prerequisites are the same as for a [regular passkey signup](signup-passkey.md#prerequisites). In addition, identifier verification must be enabled for your tenant (the `passkey_identifier_verification` feature), and your database connection must require it. Otherwise the signup challenge doesn't list any identifiers to verify, and the signup works as a regular passkey signup.

#### 1. Request a signup challenge

Request the signup challenge as usual. When verifying a phone number, you can use the `deliveryMethod` parameter to choose whether the code is sent by text message (`.text`) or voice call (`.voice`). If you don't set it, Auth0 uses the only method your tenant supports, or text message if it supports both or neither.

If the `deliveryMethod` you request isn't supported for the connection, Auth0 rejects the request with an `invalid_request` error (`The requested media is not supported for this connection`).

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

Prompt the user for the code sent to each identifier in `verificationRequired`. Store the codes in a dictionary, using the `PasskeyVerificationMethod` of each identifier as the key.

```swift
var verification: [PasskeyVerificationMethod: String] = [:]

for method in signupChallenge.verificationRequired ?? [] {
    // Prompt the user for the code sent to this identifier
    verification[method] = await promptForCode(method)
}

// e.g. [.email: "123456", .phone: "654321"]
```

Every identifier in `verificationRequired` needs a non-empty code. If a code is missing or is an empty string, the login request fails with an `invalid_request` error, which you can detect with `isPasskeyVerificationCodeMissing` (see [Handle verification errors](#5-handle-verification-errors)).

> [!TIP]
> Collect the codes **before** creating the passkey credential. That way the user doesn't create a passkey on their device for a signup that never completes.

To start over (for example, when the user asks for new codes), request a new signup challenge. A new challenge has its own `auth_session` and challenge data. Discard the previous challenge, the codes already collected, and any passkey credential created from the previous challenge, and use the new challenge from then on.

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
> If `verification` is empty, the SDK doesn't send a `verification` object at all. If the signup challenge listed identifiers in `verificationRequired`, Auth0 then rejects the request with an `invalid_request` error.

#### 5. Handle verification errors

If the login request fails, use these `AuthenticationError` properties to decide what to do next:

| Error | Condition | What to do |
|:------|:----------|:-----------|
| Wrong code | `isPasskeyVerificationCodeInvalid` is `true` | Ask the user again for the codes of the identifiers listed in `passkeyVerificationRequired`. Retry with the **same** passkey credential and the same `auth_session`, which Auth0 echoes back in `passkeyAuthSession`. |
| Missing or empty code | `isPasskeyVerificationCodeMissing` is `true` | A code for a required identifier was not sent, or was an empty string. The session stays valid. Ask the user for the code, then retry with the **same** challenge and passkey credential. |
| MFA required | `isMultifactorRequired` is `true` (HTTP 403) | Verification passed: the codes were accepted, including after a retry. The tenant requires multifactor authentication before it issues tokens, and the error carries an `mfa_token`. See [Handle MFA required](#6-handle-mfa-required). |
| Session no longer valid | `code == "invalid_grant"` and `isPasskeyVerificationCodeInvalid` is `false` | The session is expired, used up, or has run out of attempts. Request a new signup challenge and start over. |

A wrong code and a missing code are both retryable on the same session, but they are reported differently. A missing or empty code comes as an `invalid_request` error without an `auth_session`, so `passkeyAuthSession` is `nil` for it. That doesn't mean the session is lost: keep using the `auth_session` of the challenge you already have. For example:

| Request | Response | `error_description` |
|:--------|:---------|:--------------------|
| `verification` is missing, or has no `email` code (for example `{}`) | `400 invalid_request` | `Missing required parameter: verification.email` |
| `verification` has an empty `email` code (`""`) | `400 invalid_request` | `"verification.email" is not allowed to be empty` |
| `verification` has a wrong `email` code | `400 invalid_grant`, with `auth_session` and `verification_required` | `Invalid or expired session` |

> [!IMPORTANT]
> Don't check for `code == "invalid_request"` alone to detect a missing code. `invalid_request` is also returned for other problems that providing a code can't fix, such as a client or realm mismatch, or an invalid request body. Use `isPasskeyVerificationCodeMissing`, which only matches the missing and empty code errors.
>
> The error description (available through `localizedDescription`) is meant for debugging. Don't show it to the user, and don't use it to tell a wrong code from an expired session: both can read `Invalid or expired session`. Use `isPasskeyVerificationCodeInvalid` instead, which is `true` only when Auth0 sent back an `auth_session`.

The samples below run in an async context, and assume `signupChallenge` is declared with `var`.

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
} catch let error as AuthenticationError where error.isPasskeyVerificationCodeInvalid {
    // One or more codes were wrong, but the session is still alive
    let methodsToRetry = error.passkeyVerificationRequired ?? []
    print("Wrong code for: \(methodsToRetry)")

    if let authSession = error.passkeyAuthSession {
        // Use the session returned by Auth0, with the original challenge data
        signupChallenge = PasskeySignupChallenge(authenticationSession: authSession,
                                                 relyingPartyId: signupChallenge.relyingPartyId,
                                                 userId: signupChallenge.userId,
                                                 userName: signupChallenge.userName,
                                                 challengeData: signupChallenge.challengeData,
                                                 verificationRequired: methodsToRetry)
    }

    // Ask the user again for the codes of `methodsToRetry` only, then retry the login request
    // with the same `signupPasskey`
} catch let error as AuthenticationError where error.isPasskeyVerificationCodeMissing {
    // A required code is missing or empty; include it and retry with the same challenge and passkey credential
    print("Failed with: \(error)")
} catch let error as AuthenticationError where error.isMultifactorRequired {
    // The codes were accepted, but MFA is required before tokens are issued (see "Handle MFA required")
    print("MFA required")
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
        case .failure(let error) where error.isPasskeyVerificationCodeInvalid:
            // One or more codes were wrong, but the session is still alive
            let methodsToRetry = error.passkeyVerificationRequired ?? []
            print("Wrong code for: \(methodsToRetry)")
            // Update the challenge with `error.passkeyAuthSession`, ask the user again for the codes
            // of `methodsToRetry` only, and retry the login request with the same `signupPasskey`
        case .failure(let error) where error.isPasskeyVerificationCodeMissing:
            // A required code is missing or empty; include it and retry with the same challenge and passkey credential
            print("Failed with: \(error)")
        case .failure(let error) where error.isMultifactorRequired:
            // The codes were accepted, but MFA is required before tokens are issued (see "Handle MFA required")
            print("MFA required")
        case .failure(let error):
            // e.g. the session is no longer valid; request a new signup challenge and start over
            print("Failed with: \(error)")
        }
    }
```
</details>

> [!IMPORTANT]
> When retrying after a wrong or missing code, don't create a new passkey credential. Reuse the one from the first attempt. You only need a new passkey credential when you request a new signup challenge, because its challenge data is different.

#### 6. Handle MFA required

If your tenant requires multifactor authentication, the login request fails with a `403` and the `mfa_required` error. This means the verification step **passed**: the codes were accepted, and that includes a request that succeeded only after a retry (for example, after a missing or wrong code). Nothing is left to retry on the passkey session.

The error carries an `mfa_token`. Check `isMultifactorRequired` and use the token from `mfaRequiredErrorPayload` to continue with the [MFA API](../mfa-api.md#handling-mfa-required-errors): list the user's enrolled authenticators and challenge one of them, or enroll a new factor, and then verify the code. Verifying it returns the credentials.

```swift
func logIn() async throws -> Credentials? {
    do {
        return try await Auth0
            .authentication()
            .login(passkey: signupPasskey,
                   challenge: signupChallenge,
                   connection: "Username-Password-Authentication",
                   scope: "openid profile email offline_access",
                   verification: verification)
            .start()
    } catch let error as AuthenticationError where error.isMultifactorRequired {
        guard let mfaToken = error.mfaRequiredErrorPayload?.mfaToken else {
            // The response couldn't be decoded into an MFA payload
            print("MFA is required, but the MFA token could not be read")
            return nil
        }

        // Continue with the MFA API, e.g. getAuthenticators(mfaToken:factorsAllowed:), challenge(with:mfaToken:),
        // enroll(mfaToken:...) and verify(...)
        print("MFA is required")
        return nil
    }
}
```
