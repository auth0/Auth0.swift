## Embedded Auth (iOS / macOS / tvOS / watchOS / visionOS) [Beta]

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/embeddedauth)**

- [Obtain a client](#obtain-a-client)
- [Start the flow and step through next actions](#start-the-flow-and-step-through-next-actions)
- [Username](#username)
- [Password](#password)
- [Sign up](#sign-up)
- [Sign up with a password](#sign-up-with-a-password)
- [MFA flows](#mfa-flows)
- [Error handling during the flow](#error-handling-during-the-flow)

### Embedded Authorization flow

> [!IMPORTANT]
> The embedded authorization flow is currently in [Beta](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#beta). Please reach out to Auth0 support to get it enabled for your tenant and application.

#### Obtain a client

```swift
let client = Auth0.embeddedAuth()
```

> [!NOTE]
> `Auth0.embeddedAuth()` loads credentials from `Auth0.plist`. Supply them directly with `Auth0.embeddedAuth(clientId:domain:)`.

#### Start the flow and step through next actions

> [!NOTE]
> Sign-in with an email OTP (`.challengeEmail` / `.verifyOTP`) is for **existing users**. New users register through the [sign-up](#sign-up) steps (`.signup` / `.confirmSignup`), which reuse the same identify, challenge and verify steps and which the server offers only when the connection allows self-registration.

> [!NOTE]
> New next actions can be added in future releases, and `.signup` / `.confirmSignup` were added during the v4 beta. If you switch over `NextAction` or `EmbeddedCapability`, keep a `default:` branch (or handle `.unknown`) so new cases don't break your build.

`authorize(connection:)` uses a default scope of `"openid profile email offline_access"`, which ensures `Credentials.idToken` is populated after a successful `verifyOtp` or `verifyPassword`. Pass a custom `scope:` to the full `authorize(connection:capabilities:scope:audience:)` overload if needed.

```swift
func runEmbeddedAuth(connection: String) async throws -> Credentials {
    do {
        // This always throws — read reason to know what to present.
        try await client.authorize(connection: connection).start()
        fatalError("authorize always throws on the first call")
    } catch let error as EmbeddedAuthError {
        guard case .insufficientAuthorization(_, let nextActions) = error.reason else {
            throw error
        }
        return try await handleNextActions(nextActions)
    }
}

func handleNextActions(_ actions: [NextAction]) async throws -> Credentials {
    guard let action = actions.first else {
        throw EmbeddedAuthError(info: ["error": "no_next_steps"], statusCode: 0)
    }
    switch action {
    case .identifyEmail:
        let email = // … collect email from your UI …
        try await client.identify(email, type: .email).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .identifyPhone:
        let phone = // … collect phone number from your UI …
        try await client.identify(phone, type: .phone).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .identifyUsername:
        let username = // … collect username from your UI …
        try await client.identify(username, type: .username).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .challengeEmail(let index, let identifier):
        // identifier is the masked destination, e.g. "al**@example.com".
        // index selects the user's authenticator — pass it back unchanged (it is not a position in `actions`).
        try await client.challengeEmail(index: index).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .challengePhone(let index, let identifier, let deliveryMethods):
        // Pick a delivery method from deliveryMethods and show identifier to the user
        let method = deliveryMethods.first ?? .text
        try await client.challengePhone(index: index, deliveryMethod: method).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .challengePush(let index, let name):
        // name is the display name of the push device, e.g. "Diego's iPhone"
        try await client.challengePush(index: index).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .verifyOTP(let channel, let identifier):
        let otp = // … collect OTP from your UI (shown at: identifier ?? "") …
        return try await client.verifyOtp(otp, type: channel == .totp ? .totp : .oob).start()
    case .verifyOob(let pollInMs):
        return try await pollForPushApproval(pollInMs: pollInMs)
    case .verifyPassword:
        let password = // … collect password from your UI …
        return try await client.verifyPassword(password).start()
    case .verifyRecoveryCode:
        let code = // … collect recovery code from your UI …
        try await client.verifyRecoveryCode(code).start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .confirmRecoveryCode(let newCode):
        // Display newCode to the user so they can record it before continuing.
        return try await client.confirmRecoveryCode().start()
    case .signup(let identifiers, let passwordRequirement):
        // The server offers to register a new user. identifiers lists the identifiers it accepts
        // and whether each is required. passwordRequirement says whether a password will be asked for
        // at the end: .none, .optional or .required. Call signup() only if the user chose to create an account.
        try await client.signup().start()
        throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
    case .confirmSignup(let password):
        // The registration steps are complete. This finishes the sign-up and signs the user in.
        // password is nil when the connection does not collect one. Otherwise ask the user for it,
        // see "Sign up with a password".
        var entered: String?
        if let password {
            // Your own UI. Return nil to skip the password when !password.isRequired.
            entered = await askUserForPassword(rules: password.complexity, isRequired: password.isRequired)
        }
        return try await client.confirmSignup(password: entered).start()
    case .unknown:
        throw EmbeddedAuthError(info: ["error": "unsupported_action"], statusCode: 0)
    }
}
```

<details>
  <summary>Using callbacks</summary>

```swift
Auth0.embeddedAuth()
    .authorize(connection: "my-connection")
    .start { result in
        switch result {
        case .success:
            // authorize() always fails on the first call — unreachable in practice
            break
        case .failure(let error):
            if case .insufficientAuthorization(_, let nextActions) = error.reason,
               case .identifyEmail = nextActions.first {
                // Show email input
            } else {
                print("Failed with: \(error)")
            }
        }
    }
```
</details>

#### Username

When `nextActions` contains `.identifyUsername`, submit the username with `identify(_:type:)` and `.username`. It continues like the email and phone steps. `.verifyPassword` is the next step for a username, because the server requires a password for username sign-in.

The connection's username rules apply. A malformed username comes back as `.invalidRequest`, which ends the flow.

```swift
try await client.identify("alice", type: .username).start()
```

#### Password

When `nextActions` contains `.verifyPassword`, submit the user's password with `verifyPassword(_:)`. Like `verifyOtp`, it returns `Credentials` on success. If the user has to complete a second factor, it instead fails with `.insufficientAuthorization` and the MFA actions in `nextActions` (see below).

A wrong password fails with `.insufficientAuthorization(.invalidIdentifierOrPassword, nextActions)`. The flow stays live on a rotated session, and `nextActions` is `[.verifyPassword]` again, so show the error and present the password step once more. The server deliberately does not say whether the password or the user was wrong.

If a second factor is required but the user has no enrolled factor, `verifyPassword` fails with `.noEligibleFactors` after a correct password. The flow has ended: fall back to a redirect-based flow such as Universal Login.

An empty password is sent to the server like any other and comes back as `.invalidRequest`, which ends the flow. Disable the submit button while the field is empty.

After a wrong password the server offers only `.verifyPassword` again, never an identify step. To let the user correct the username or email, start a new flow with `authorize()`. Do not let the user retry endlessly: after several failures, offer a password reset or a different account.

```swift
func signIn(password: String) async throws -> Credentials {
    do {
        return try await client.verifyPassword(password).start()
    } catch let error as EmbeddedAuthError {
        switch error.reason {
        case .insufficientAuthorization(.invalidIdentifierOrPassword, let nextActions):
            // Show "incorrect username or password". nextActions is [.verifyPassword]: ask for the password again.
            return try await handleNextActions(nextActions)
        case .noEligibleFactors:
            // The password was right but a second factor is required and none is enrolled.
            throw error
        case .insufficientAuthorization(_, let nextActions):
            // Any other continuation, for example a second factor after the password.
            return try await handleNextActions(nextActions)
        default:
            throw error
        }
    }
}
```

#### Sign up

When `nextActions` contains `.signup(identifiers:passwordRequirement:)`, the connection allows self-registration. `identifiers` lists what the server collects for the new account: `.email` and/or `.phone`, each with `isRequired`. Use it to decide which fields to show. Identifiers this SDK does not recognise are left out, so the list can be empty. A username is never offered. `passwordRequirement` says whether the connection also collects a password at the end, see [Sign up with a password](#sign-up-with-a-password).

**Choose the capabilities.** `authorize(connection:)` advertises every capability, including sign-up. To keep sign-up out of a login screen, pass the capabilities explicitly. Without `.signup` and `.confirmSignup` the server never offers it. For a sign-up screen, advertise what sign-up uses:

```swift
// Login: everything except sign-up.
let loginCapabilities = EmbeddedCapability.all.filter { $0 != .signup && $0 != .confirmSignup }

// Sign-up: the sign-up actions, email and phone identification, their challenges and the code check.
let signupCapabilities: [EmbeddedCapability] = [
    .signup, .identifyEmail, .identifyPhone,
    .challengeEmail, .challengePhone, .verifyOTP, .confirmSignup
]

// On the login screen:
try await client.authorize(connection: connection,
                           capabilities: loginCapabilities,
                           scope: "openid profile email offline_access",
                           audience: nil).start()
```

**Collect one or more identifiers.** `signup()` never returns credentials: it always fails with `.insufficientAuthorization` and the `nextActions` for the next step. When `identifiers` lists both `.email` and `.phone`, the registration collects both with the same steps used for login: identify an identifier, send and verify its code, then do the same for the other. The server offers the identify steps it still needs, and your app picks which one to do next, so follow `nextActions` after every step instead of assuming a fixed sequence. Once every required identifier is verified the server offers `.confirmSignup(password:)`. Call `confirmSignup()` then, or `confirmSignup(password:)` when the connection collects a password. Like `verifyOtp`, it returns `Credentials` on success. An identifier that is not required can be left out: the server offers `.confirmSignup` without it.

This example signs a user up with an email and a phone number, and a password when the connection collects one. It does the email first, then the phone number. Pass `nil` for an identifier the user left empty. An empty value is never sent, because the server rejects it:

```swift
/// Runs a step that is expected to continue the flow. Returns whether the last code was wrong, and the
/// `nextActions` the server offers.
func continuation(after step: () async throws -> Void) async throws -> (wrongCode: Bool, nextActions: [NextAction]) {
    do {
        try await step()
    } catch let error as EmbeddedAuthError {
        guard case .insufficientAuthorization(let reason, let nextActions) = error.reason else { throw error }
        switch reason {
        case .invalidCode, .invalidIdentifierOrCode: return (true, nextActions)
        default: return (false, nextActions)
        }
    }
    // During sign-up only confirmSignup() returns credentials, so a step that succeeds is unexpected.
    throw EmbeddedAuthError(info: ["error": "unexpected_success"], statusCode: 0)
}

extension NextAction {
    var isConfirmSignup: Bool {
        if case .confirmSignup = self { return true }
        return false
    }
}

func signUp(email: String?,
            phone: String?,
            password: String?,
            askForCode: (_ sentTo: String?, _ lastCodeWasWrong: Bool) async -> String,
            askForPassword: (_ lastPasswordWasRejected: Bool) async -> String?) async throws -> Credentials {
    var password = password
    var step = try await continuation {
        try await client.authorize(connection: connection,
                                   capabilities: signupCapabilities,
                                   scope: "openid profile email offline_access",
                                   audience: nil).start()
    }
    // Only start the registration if the connection allows it, and every required identifier was provided.
    guard let identifiers = step.nextActions.compactMap({ action -> [SignupIdentifier]? in
        if case .signup(let identifiers, _) = action { return identifiers }
        return nil
    }).first else {
        throw EmbeddedAuthError(info: ["error": "signup_not_offered"], statusCode: 0)
    }
    for identifier in identifiers where identifier.isRequired {
        let value = identifier.type == .email ? email : phone
        if value?.isEmpty != false {
            throw EmbeddedAuthError(info: ["error": "missing_required_identifier"], statusCode: 0)
        }
    }
    step = try await continuation { try await client.signup().start() }

    var identified = Set<IdentifierType>()
    var verified = Set<OtpChannel>()
    for _ in 0..<12 {
        let actions = step.nextActions
        // An identifier the user entered is still sent while the server asks for it, even if sign-up could
        // already be confirmed without it.
        let emailPending = actions.contains(.identifyEmail) && email?.isEmpty == false && !identified.contains(.email)
        let phonePending = actions.contains(.identifyPhone) && phone?.isEmpty == false && !identified.contains(.phone)

        if actions.contains(where: \.isConfirmSignup), !emailPending, !phonePending {
            // Every required identifier is verified: create the account and sign the user in.
            do {
                return try await client.confirmSignup(password: password).start()
            } catch let error as EmbeddedAuthError {
                guard case .insufficientAuthorization(let reason, let nextActions) = error.reason else { throw error }
                switch reason {
                case .passwordRequired:
                    password = await askForPassword(false)
                case .invalidPassword:
                    password = await askForPassword(true)
                case .passwordNotAccepted:
                    // The connection does not collect a password: confirm without one.
                    password = nil
                default:
                    throw error
                }
                // The flow is still live: nextActions offers .confirmSignup again.
                step = (false, nextActions)
                continue
            }
        }
        if let (channel, sentTo) = actions.compactMap({ action -> (OtpChannel, String?)? in
            if case .verifyOTP(let channel, let identifier) = action { return (channel, identifier) }
            return nil
        }).first {
            let code = await askForCode(sentTo, step.wrongCode)
            step = try await continuation {
                _ = try await client.verifyOtp(code, type: channel == .totp ? .totp : .oob).start()
            }
            if !step.wrongCode { verified.insert(channel) }
        } else if !verified.contains(.email), let index = actions.compactMap({ action -> Int? in
            if case .challengeEmail(let index, _) = action { return index }
            return nil
        }).first {
            step = try await continuation { try await client.challengeEmail(index: index).start() }
        } else if !verified.contains(.sms), !verified.contains(.voice),
                  let (index, methods) = actions.compactMap({ action -> (Int, [PhoneDeliveryMethod])? in
                      if case .challengePhone(let index, _, let methods) = action { return (index, methods) }
                      return nil
                  }).first {
            let method = methods.first ?? .text
            step = try await continuation { try await client.challengePhone(index: index, deliveryMethod: method).start() }
        } else if emailPending, let email {
            identified.insert(.email)
            step = try await continuation { try await client.identify(email, type: .email).start() }
        } else if phonePending, let phone {
            identified.insert(.phone)
            step = try await continuation { try await client.identify(phone, type: .phone).start() }
        } else {
            throw EmbeddedAuthError(info: ["error": "unsupported_action"], statusCode: 0)
        }
    }
    throw EmbeddedAuthError(info: ["error": "too_many_steps"], statusCode: 0)
}
```

<details>
  <summary>Using callbacks</summary>

```swift
// When nextActions contains .signup(identifiers:passwordRequirement:) and the user chose to create an account.
// Use the same client instance for every step: it holds the session.
client.signup().start { result in
    switch result {
    case .success:
        // signup() always fails with the next step — unreachable in practice
        break
    case .failure(let error):
        if case .insufficientAuthorization(_, let nextActions) = error.reason {
            // Present nextActions, for example .identifyEmail, then its challenge and verifyOtp steps
            _ = nextActions
        } else {
            // For example .accessDenied: the server rejected the sign-up. Start over with authorize().
            print("Failed with: \(error)")
        }
    }
}

// When nextActions contains .confirmSignup(password:). Pass nil when the connection does not collect a password,
// or when the password is optional and the user skipped it.
client.confirmSignup(password: password).start { result in
    switch result {
    case .success(let credentials):
        // The account is created and the user is signed in
        _ = credentials
    case .failure(let error):
        switch error.reason {
        case .network:
            // The session is kept, but the SDK does not keep the password: call confirmSignup(password:) again with it
            break
        case .insufficientAuthorization(.passwordRequired, _), .insufficientAuthorization(.invalidPassword, _):
            // Ask the user for a (new) password, then call confirmSignup(password:) again
            break
        case .insufficientAuthorization(.passwordNotAccepted, _):
            // The connection does not collect a password: call confirmSignup()
            break
        case .passwordLeaked:
            // The password appears in a data breach. The flow has ended: start over with authorize()
            break
        default:
            print("Failed with: \(error)")
        }
    }
}
```
</details>

**Handle rejections.** If the server rejects the new user before registration, for example because of a pre-registration validation or an Action that denies the sign-up, the request fails with `.accessDenied` and the flow ends. Start a new flow with `authorize()` and show the user a generic message. `signup()`, `confirmSignup()` and `confirmSignup(password:)` need an active session and fail locally with `.noActiveSession` otherwise. If `confirmSignup(password:)` fails with `.network` while exchanging the code, the session is kept and a retry sends the confirmation again. The server decides whether it can still complete. The SDK never keeps the password, so pass it again when you retry.

**An identifier that already has an account.** Signing up with an email or phone number that already has an account does not return an error, so sign-up can't be used to find out which accounts exist. The server answers each step as it would for a new identifier but sends no code, so any code the user enters fails with `.insufficientAuthorization(.invalidIdentifierOrCode, nextActions)`, the same as a mistyped code, until the attempt limit ends the flow with `.tooManyWrongOtpAttempts`. Requesting codes again is limited too and ends the flow with `.accessDenied`. While that identifier is required, the server never offers `.confirmSignup`. If it is optional, the user can leave it out and the account is created without it. Your app can't tell this case apart from a mistyped code, so on the code screen offer a way out, such as "Already have an account? Sign in", which starts a new login flow with `authorize()`.

##### Sign up with a password

Some connections also collect a password, as the last step of the sign-up. The identifiers are collected and verified as above. The password is sent with `confirmSignup(password:)`, which creates the account.

| Connection | `.signup` `passwordRequirement` | `.confirmSignup` `password` | What the app does |
|---|---|---|---|
| No password | `.none` | `nil` | `confirmSignup()` |
| Password required | `.required` | set, `isRequired` is `true` | `confirmSignup(password:)` |
| Password optional | `.optional` | set, `isRequired` is `false` | `confirmSignup(password:)`, or `confirmSignup()` to skip |

`passwordRequirement` lets the first screen tell the user a password is coming. When the value is wrapped in an `Optional`, write `CredentialRequirement.none`: a bare `.none` is read as `Optional.none`.

`.confirmSignup(password:)` tells you what to render. `password` is `nil` when there is no password to collect. Otherwise show a password field, mandatory when `isRequired` is `true`, and use `complexity` for hints. The server does not repeat `isRequired` at the confirm step: the client remembers it from the sign-up offer at the start of the flow, so use the same client for the whole flow. If the client never saw the offer, `isRequired` is `true`, and a skipped password that the connection requires comes back as `.passwordRequired`.

The hints are advisory. The server is authoritative, so a password that satisfies them can still be rejected:

- `complexity.minLength` counts UTF-16 code units. Count with `password.utf16.count`, not `password.count`.
- `complexity.characterTypes` lists the character types the password must contain; all of them are required. It is empty when the server lists none, and types this SDK does not recognise are left out.
- Rules such as "at least 3 of the 4 character types" are not included, but they are still enforced.

`nil` creates the account without a password, which only works when the password is optional. An empty string is sent as is, like the password of `verifyPassword(_:)`, and nothing is trimmed. The SDK does not check the length or the complexity locally. A password longer than 2048 characters comes back as `.invalidRequest`, which ends the flow.

```swift
func finishSignUp(password: SignupPassword?, askForPassword: (_ lastPasswordWasRejected: Bool) async -> String?) async throws -> Credentials {
    var entered: String?
    var networkRetries = 0
    if password != nil { entered = await askForPassword(false) }
    while true {
        do {
            return try await client.confirmSignup(password: entered).start()
        } catch let error as EmbeddedAuthError {
            switch error.reason {
            case .insufficientAuthorization(.passwordRequired, _):
                // The connection needs a password and none was sent: ask for one.
                entered = await askForPassword(false)
            case .insufficientAuthorization(.invalidPassword, _):
                // The connection's password policy rejected it: show the hints again and ask for another one.
                entered = await askForPassword(true)
            case .insufficientAuthorization(.passwordNotAccepted, _):
                // The connection does not collect a password: confirm without one.
                entered = nil
            case .network:
                // The session is kept, but the SDK does not keep the password: send it again, a few times at most.
                networkRetries += 1
                guard networkRetries <= 3 else { throw error }
                try await Task.sleep(nanoseconds: 1_000_000_000)
            case .passwordLeaked:
                // The password appears in a data breach. The flow has ended: start over with authorize().
                throw error
            default:
                throw error
            }
        }
    }
}
```

<details>
  <summary>Using callbacks</summary>

```swift
// Pass nil to skip an optional password, or when the connection does not collect one.
client.confirmSignup(password: enteredPassword).start { result in
    switch result {
    case .success(let credentials):
        _ = credentials
    case .failure(let error):
        switch error.reason {
        case .insufficientAuthorization(.passwordRequired, _), .insufficientAuthorization(.invalidPassword, _):
            // The flow is still live. Ask for a (new) password and call confirmSignup(password:) again.
            break
        case .insufficientAuthorization(.passwordNotAccepted, _):
            // Call confirmSignup() instead.
            break
        case .network:
            // The SDK does not keep the password: call confirmSignup(password:) again with it.
            break
        default:
            // For example .passwordLeaked: the flow has ended. Start over with authorize().
            print("Failed with: \(error)")
        }
    }
}
```
</details>

`.passwordRequired`, `.passwordNotAccepted` and `.invalidPassword` keep the flow live on a rotated session, and `nextActions` offers `.confirmSignup` again. `.passwordLeaked` ends the flow: the password appears in a data breach, so start a new flow with `authorize()` and let the user choose a different password. Do not log or store the password.

#### MFA flows

After the primary factor succeeds the server may require a second factor. The `nextActions` in the continuation will include the user's eligible MFA factors. Handle them just like any other continuation step.

**Push notification (polling)**

```swift
func pollForPushApproval(pollInMs: Int) async throws -> Credentials {
    var intervalMs = pollInMs
    while true {
        // Wait before every poll, including the first: polling sooner than poll_in_ms is answered with slow_down.
        try await Task.sleep(nanoseconds: UInt64(intervalMs) * 1_000_000)
        do {
            return try await client.verifyOob().start()
        } catch let error as EmbeddedAuthError {
            switch error.reason {
            case .insufficientAuthorization(.authorizationPending, let next),
                 .insufficientAuthorization(.slowDown, let next):
                // Not approved yet, or polled too early. Use the interval from the latest
                // response — after slow_down it is longer than before.
                intervalMs = next.compactMap {
                    if case .verifyOob(let ms) = $0 { return ms } else { return nil }
                }.first ?? intervalMs
            default:
                throw error
            }
        }
    }
}
```

**Recovery code (with rotation)**

```swift
// Step 1: submit the current recovery code
do {
    try await client.verifyRecoveryCode(currentCode).start()
} catch let error as EmbeddedAuthError {
    if case .insufficientAuthorization(_, let next) = error.reason,
       case .confirmRecoveryCode(let newCode) = next.first {
        // Step 2: show newCode to the user so they record it
        showNewRecoveryCode(newCode)
        // Step 3: confirm and receive credentials
        let credentials = try await client.confirmRecoveryCode().start()
    }
}
```

#### Error handling during the flow

```swift
do {
    let credentials = try await client.verifyOtp(otp, type: .oob).start()
    // Use credentials
} catch let error as EmbeddedAuthError {
    switch error.reason {
    case .insufficientAuthorization(_, let nextActions):
        // Flow is still live — present the next action's UI.
        _ = nextActions
    case .challengeExpired:
        // The push challenge expired or was not found — the flow has ended, start over with authorize().
        break
    case .tooManyWrongOtpAttempts:
        // Too many wrong attempts — start over with authorize().
        break
    case .authorizationRejected:
        // Push notification was denied — start over with authorize().
        break
    case .noEligibleFactors:
        // User has no enrolled MFA factors — fall back to a redirect-based flow.
        break
    case .consentRequired:
        // Consent can't be collected in the embedded flow — sign in with a redirect-based flow such as Universal Login.
        break
    case .noNextSteps:
        // No further action is available — check the capabilities passed to authorize(), then start over.
        break
    case .passwordLeaked:
        // The password appears in a data breach (at login or sign-up) — the flow has ended: start over with authorize()
        // and ask the user to choose a different password.
        break
    case .accessDenied:
        // Other terminal denial — start over with authorize().
        break
    case .tooManyAttempts, .tooManyLogins, .ipBlocked:
        // Rate-limited by attack protection — the flow has ended. Ask the user to try again later, then start over with authorize().
        break
    case .sessionExpired:
        // The grant expired — start over with authorize().
        break
    case .network:
        // Transient failure — retry the same step.
        break
    default:
        print("Failed with: \(error)")
    }
}
```

##### Retryable errors

`.insufficientAuthorization` carries a sub-reason that says why the server still needs input. All of them keep the flow live: the SDK switches to the rotated session, so the user can retry the step in `nextActions` without restarting.

| Server `error_description` | Sub-reason | When it is returned | What to do |
|---|---|---|---|
| `invalid_identifier_or_code` | `.invalidIdentifierOrCode` | The identifier or one-time code was rejected on the primary path. It is ambiguous on purpose, so a wrong code and an unknown user look the same. | Show a generic "incorrect code" message and let the user retry. |
| `invalid_code` | `.invalidCode` | A one-time code or recovery code was wrong for a user the server has already identified. | Let the user re-enter the code. |
| `authorization_pending` | `.authorizationPending` | The push notification has not been approved yet. | Wait for the `pollInMs` from `.verifyOob(pollInMs:)`, then call `verifyOob()` again. |
| `invalid_identifier_or_password` | `.invalidIdentifierOrPassword` | The identifier (email, phone or username) or the password was rejected. It is ambiguous on purpose, so a wrong password and an unknown user look the same. | Show a generic "incorrect username or password" message and present `nextActions` again; it holds `.verifyPassword`. |
| `slow_down` | `.slowDown` | `verifyOob()` was called before `pollInMs` elapsed. | Wait longer than before, then poll again. |
| `password_required` | `.passwordRequired` | `confirmSignup` was called without a password, but the connection requires one. | Ask for a password and call `confirmSignup(password:)` again. |
| `password_not_accepted` | `.passwordNotAccepted` | `confirmSignup(password:)` was called with a password, but the connection does not collect one. | Call `confirmSignup()` without a password. |
| `invalid_password` | `.invalidPassword` | The password does not meet the connection's password policy. | Show the hints again, ask for another password and call `confirmSignup(password:)` again. |

```swift
guard case .insufficientAuthorization(let subReason, let nextActions) = error.reason else {
    throw error
}
switch subReason {
case .invalidIdentifierOrCode, .invalidCode, .invalidIdentifierOrPassword:
    // The user entered something wrong — show an error and present nextActions again.
    break
case .authorizationPending, .slowDown:
    // Only returned while polling verifyOob() — see "Push notification (polling)".
    break
case .passwordRequired, .passwordNotAccepted, .invalidPassword:
    // Only returned by confirmSignup(password:) — see "Sign up with a password".
    break
case .none:
    // A plain continuation — present nextActions.first.
    break
}
```

[Go up ⤴](../EXAMPLES.md#examples)
