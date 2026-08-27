### Verify MFA

After enrolling or challenging an MFA factor, you need to verify the code to complete authentication.

#### Verify with OOB code

Verify an out-of-band (OOB) code received via SMS or email.

```swift
Auth0
    .mfa()
    .verify(oobCode: "123456", bindingCode: nil, mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

With a binding code for enhanced security:

```swift
Auth0
    .mfa()
    .verify(oobCode: "oob_code_value", bindingCode: "BINDING_CODE", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
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
        .mfa()
        .verify(oobCode: "123456", bindingCode: nil, mfaToken: mfaToken)
        .start()
    print("MFA verification successful!")
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
    .mfa()
    .verify(oobCode: "123456", bindingCode: nil, mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("MFA verification successful!")
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

#### Verify with OTP code

Verify a one-time password (OTP) code from an authenticator app.

```swift
Auth0
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
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
        .mfa()
        .verify(otp: "123456", mfaToken: mfaToken)
        .start()
    print("MFA verification successful!")
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
    .mfa()
    .verify(otp: "123456", mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("MFA verification successful!")
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

#### Verify with recovery code

Verify using a recovery code when the primary MFA factor is unavailable.

```swift
Auth0
    .mfa()
    .verify(recoveryCode: "RECOVERY_CODE_123", mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let credentials):
            print("MFA verification successful!")
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
        .mfa()
        .verify(recoveryCode: "RECOVERY_CODE_123", mfaToken: mfaToken)
        .start()
    print("MFA verification successful!")
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
    .mfa()
    .verify(recoveryCode: "RECOVERY_CODE_123", mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { credentials in
        print("MFA verification successful!")
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>
