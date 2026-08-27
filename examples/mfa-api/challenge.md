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
                print("OOB Code: \(oobCode)")
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
        print("OOB Code: \(oobCode)")
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
            print("OOB Code: \(oobCode)")
        }
    })
    .store(in: &cancellables)
```
</details>
