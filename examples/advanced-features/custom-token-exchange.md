### Custom Token Exchange

[Custom Token Exchange](https://auth0.com/docs/authenticate/custom-token-exchange) allows you to enable applications to exchange their existing tokens for Auth0 tokens when calling the /oauth/token endpoint. This is useful for advanced integration use cases, such as:
- Get Auth0 tokens for another audience
- Integrate an external identity provider 
- Migrate to Auth0
- Delegation and impersonation (using actor tokens)

> [!NOTE]
> This feature is currently available in [Early Access](https://auth0.com/docs/troubleshoot/product-lifecycle/product-release-stages#early-access). Please reach out to Auth0 support to get it enabled for your tenant.

#### Exchange to obtain Auth0 credentials using an existing identity provider token

```swift
Auth0
    .authentication()
    .customTokenExchange(subjectToken: "existing-token",
                         subjectTokenType: "urn:ietf:params:oauth:token-type:jwt",
                         audience: "https://example.com/api",
                         scope: "openid profile email",
                         organization: "org_id")
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
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
        .customTokenExchange(subjectToken: "existing-token",
                            subjectTokenType: "urn:ietf:params:oauth:token-type:jwt",
                            audience: "https://example.com/api",
                            scope: "openid profile email",
                            organization: "org_id")
        .start()
    print("Obtained credentials: \(credentials)")
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
    .customTokenExchange(subjectToken: "existing-token",
                         subjectTokenType: "urn:ietf:params:oauth:token-type:jwt",
                         audience: "https://example.com/api",
                         scope: "openid profile email",
                         organization: "org_id")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

#### Delegation and impersonation with actor tokens

You can perform a token exchange with an actor token to support delegation and impersonation flows (per [RFC 8693](https://tools.ietf.org/html/rfc8693)). The actor token identifies the party that is acting on behalf of the subject.

Use the `ActorToken` struct to bundle the actor token and its type together:

```swift
let actor = ActorToken(token: "actor-id-token",
                       tokenType: "urn:ietf:params:oauth:token-type:id_token")

Auth0
    .authentication()
    .customTokenExchange(subjectToken: "subject-token",
                         subjectTokenType: "urn:ietf:params:oauth:token-type:id_token",
                         actorToken: actor)
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
let actor = ActorToken(token: "actor-id-token",
                       tokenType: "urn:ietf:params:oauth:token-type:id_token")

do {
    let credentials = try await Auth0
        .authentication()
        .customTokenExchange(subjectToken: "subject-token",
                             subjectTokenType: "urn:ietf:params:oauth:token-type:id_token",
                             actorToken: actor)
        .start()
    print("Obtained credentials: \(credentials)")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
let actor = ActorToken(token: "actor-id-token",
                       tokenType: "urn:ietf:params:oauth:token-type:id_token")

Auth0
    .authentication()
    .customTokenExchange(subjectToken: "subject-token",
                         subjectTokenType: "urn:ietf:params:oauth:token-type:id_token",
                         actorToken: actor)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> When an actor token is provided, Auth0 will not issue a refresh token regardless of whether `offline_access` is in the scope.

#### Reading the `act` claim from the ID token

When a token exchange involves an actor token, Auth0 may include an `act` (actor) claim in the resulting ID token. This claim identifies who is acting on behalf of the subject and may be nested to represent delegation chains.

> [!NOTE]
> The `act` claim is set server-side via an Auth0 Action that calls `api.authentication.setActor()`. Without this Action configured, the ID token will not contain an `act` claim even when an actor token is provided in the request.

The `act` claim is exposed through the `UserInfo` type via the `ActClaim` class. This example uses [JWTDecode.swift](https://github.com/auth0/JWTDecode.swift) to decode the ID token — add it to your project if you haven't already:

```swift
import JWTDecode

let jwt = try decode(jwt: credentials.idToken)
let userInfo = UserInfo(json: jwt.body)

if let act = userInfo?.act {
    print("Actor: \(act.sub)")
    print("Additional claims: \(act.additionalClaims)")

    // Check for delegation chain
    if let innerAct = act.act {
        print("Original actor: \(innerAct.sub)")
    }
}
```

The `ActClaim` class provides:
- `sub`: The subject identifier of the acting party.
- `act`: A nested `ActClaim` for delegation chains (e.g., `act.act` for multi-hop delegation).
- `additionalClaims`: Any extra claims beyond `sub` and `act` (e.g., `org`, `role`).

You can also access the `act` claim from the Credentials Manager's stored user information:

```swift
if let act = credentialsManager.user?.act {
    print("Actor: \(act.sub)")
}
```
