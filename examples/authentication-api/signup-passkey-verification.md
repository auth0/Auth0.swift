### Sign up with passkey and identifier verification

When your database connection requires the user's email address or phone number to be verified, Auth0 sends a one-time code (OTP) to each identifier that needs verification as part of the [passkey signup](signup-passkey.md) flow. The user must enter those codes before the passkey signup can be completed.

The flow is the same as a regular passkey signup, with two additions:

1. The signup challenge lists the identifiers that need verification in `verificationRequired`.
2. The collected codes are sent along with the passkey credential in the `verification` parameter.

> [!NOTE]
> The prerequisites are the same as for a [regular passkey signup](signup-passkey.md#prerequisites). In addition, identifier verification must be enabled for your tenant (the `passkey_identifier_verification` feature), and your database connection must require it. Otherwise the signup challenge doesn't list any identifiers to verify, and the signup works as a regular passkey signup.

#### 1. Request a signup challenge

Request the signup challenge as usual. When verifying a phone number, you can use the `deliveryMethod` parameter to choose whether the code is sent by text message (`.text`) or voice call (`.voice`). If you don't set it, Auth0 uses the only method your tenant supports, or text message if it supports both or neither.

`deliveryMethod` only applies to the **phone** code. If only an email address has to be verified, it is ignored: the request succeeds without an error, even with `.voice`, and the code is sent to the email address as usual. If a phone code has to be sent and the channel you request isn't enabled for the tenant, Auth0 rejects the request with an `invalid_request` error (`The requested media is not supported for this connection`).

> [!IMPORTANT]
> If you pass an `organization`, use the organization **ID** (`org_…`), not its name. `/passkey/register` rejects a name with `authorization request parameter organization must be an organization id`. Pass the same ID to `login(passkey:…)`.

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

Only `.email` and `.phone` are accepted as keys by Auth0. A `.unknown` key is rejected by the server as an invalid request.

Every identifier in `verificationRequired` needs a non-empty code. Before sending the request, the SDK checks the `verification` you pass against the `verificationRequired` you pass (or the one of the challenge you pass). If a required code is missing, is an empty string, or has only spaces or newlines, `login` fails with an `invalid_request` error and nothing is sent. Make sure every code is filled in before you call `login` (see [Handle verification errors](#5-handle-verification-errors)). When `verificationRequired` is `nil` or empty, nothing is checked.

> [!TIP]
> Collect the codes **before** creating the passkey credential. That way the user doesn't create a passkey on their device for a signup that never completes.

To start over (for example, when the user asks for new codes), request a new signup challenge. A new challenge has its own `auth_session` and challenge data. Discard the previous challenge, the codes already collected, and any passkey credential created from the previous challenge, and use the new challenge from then on.

#### 3. Create a new passkey credential

Create the passkey credential from the signup challenge, exactly as in a [regular passkey signup](signup-passkey.md#2-create-a-new-passkey-credential).

#### 4. Log the new user in

Pass the passkey credential, the signup challenge, and the collected codes to `login(passkey:challenge:connection:audience:scope:organization:verification:)`.

That method is a shorthand for `login(passkey:verificationRequired:authSession:connection:audience:scope:organization:verification:)`, which takes two values separately. You can call it directly, and you need it to retry after a wrong code. `verificationRequired` is the list of identifiers whose codes have to be in `verification`, and it can come from two places:

| When | `verificationRequired` | `authSession` |
|:-----|:-----------------------|:--------------|
| First attempt, right after the signup challenge | `signupChallenge.verificationRequired` | `signupChallenge.authenticationSession` |
| Retry after a wrong code (`isPasskeyVerificationRetryable` is `true`) | `error.passkeyVerificationRequired`: only the identifiers that are still unverified | `error.passkeyAuthSession`: the same session as before |

An empty `verificationRequired` means that verification is not enabled, or is not required for any identifier. Nothing is checked then.

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
               verificationRequired: verificationRequired,
               authSession: authSession,
               connection: "Username-Password-Authentication",
               scope: "openid profile email offline_access",
               verification: verification)
        .start()
    print("Obtained credentials")
} catch let error as AuthenticationError where error.isPasskeyVerificationRetryable {
    // One or more codes were wrong, but the session is still alive. Auth0 lists the identifiers that are
    // still unverified, and echoes back the session
    verificationRequired = error.passkeyVerificationRequired ?? verificationRequired
    authSession = error.passkeyAuthSession ?? authSession
    print("Wrong code for: \(verificationRequired)")

    // Ask the user again for the codes of `verificationRequired` only, then call login again with the same
    // `signupPasskey`, `verificationRequired` and `authSession`
} catch let error as AuthenticationError where error.isMultifactorRequired {
    // The codes were accepted, but MFA is required before tokens are issued (see "Handle MFA required")
    print("MFA required")
} catch let error as AuthenticationError where error.isTooManyAttempts {
    // Brute force protection blocked the user: waiting doesn't help, they have to unblock the account first.
    // Check this before the 429 below, because the block is also a 429
    print("Account blocked: \(error)")
} catch let error as AuthenticationError where error.statusCode == 429 {
    // Auth0 is rate limiting the requests (HTTP 429); ask the user to try again later
    print("Rate limited: \(error)")
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
           verificationRequired: verificationRequired,
           authSession: authSession,
           connection: "Username-Password-Authentication",
           scope: "openid profile email offline_access",
           verification: verification)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials")
        case .failure(let error) where error.isPasskeyVerificationRetryable:
            // One or more codes were wrong, but the session is still alive
            verificationRequired = error.passkeyVerificationRequired ?? verificationRequired
            authSession = error.passkeyAuthSession ?? authSession
            print("Wrong code for: \(verificationRequired)")
            // Ask the user again for the codes of `verificationRequired` only, then call login again with the
            // same `signupPasskey`, `verificationRequired` and `authSession`
        case .failure(let error) where error.isMultifactorRequired:
            // The codes were accepted, but MFA is required before tokens are issued (see "Handle MFA required")
            print("MFA required")
        case .failure(let error) where error.isTooManyAttempts:
            // Brute force protection blocked the user: waiting doesn't help, they have to unblock the account first
            print("Account blocked: \(error)")
        case .failure(let error) where error.statusCode == 429:
            // Auth0 is rate limiting the requests (HTTP 429); ask the user to try again later
            print("Rate limited: \(error)")
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

> [!NOTE]
> If you implement the `Authentication` protocol yourself, for example in a mock or a wrapper, also implement `login(passkey:verificationRequired:authSession:connection:audience:scope:organization:verification:)`, whose `verification` parameter is a dictionary that is empty when there are no codes, and `passkeySignupChallenge(…deliveryMethod:)`. The default implementations of these two methods call themselves, so a type that doesn't implement them crashes when they are called.
