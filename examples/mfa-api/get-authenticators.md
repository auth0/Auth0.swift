### Get available authenticators

After receiving an MFA token, you can retrieve the list of available authenticators that the user has already enrolled. Use the factors from the `challenge` field of the MFA required error payload to filter the authenticators.

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
