### Enroll MFA factors

When MFA enrollment is required, you can enroll various types of MFA factors.

#### Enroll SMS

Enroll a phone number for SMS-based MFA. An SMS with a verification code will be sent to the phone number.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
    .start { result in
        switch result {
        case .success(let challenge):
            print("SMS enrollment initiated")
            print("OOB Code: \(challenge.oobCode)")
            // Now prompt user for the code they received via SMS
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
        .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
        .start()
    print("SMS enrollment initiated")
    print("OOB Code: \(challenge.oobCode)")
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
    .enroll(mfaToken: mfaToken, phoneNumber: "+12025550135")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("SMS enrollment initiated")
        print("OOB Code: \(challenge.oobCode)")
    })
    .store(in: &cancellables)
```
</details>

#### Enroll email

Enroll an email address for email-based MFA. A verification code will be sent to the email address.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken, email: "user@example.com")
    .start { result in
        switch result {
        case .success(let challenge):
            print("Email enrollment initiated")
            print("OOB Code: \(challenge.oobCode)")
            // Now prompt user for the code they received via email
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
        .enroll(mfaToken: mfaToken, email: "user@example.com")
        .start()
    print("Email enrollment initiated")
    print("OOB Code: \(challenge.oobCode)")
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
    .enroll(mfaToken: mfaToken, email: "user@example.com")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("Email enrollment initiated")
        print("OOB Code: \(challenge.oobCode)")
    })
    .store(in: &cancellables)
```
</details>

#### Enroll OTP (TOTP)

Enroll a time-based one-time password (TOTP) authenticator. This returns a QR code and secret that can be scanned by authenticator apps like Google Authenticator or Authy.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let challenge):
            print("OTP enrollment initiated")
            if let barcodeUri = challenge.barcodeUri {
                print("QR Code URI: \(barcodeUri)")
                // Display this as a QR code for the user to scan
            }
            if let secret = challenge.secret {
                print("Secret: \(secret)")
                // User can manually enter this into their authenticator app
            }
            // After user scans QR code and sets up authenticator app,
            // prompt them for the OTP code to complete enrollment
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
        .enroll(mfaToken: mfaToken)
        .start()
    print("OTP enrollment initiated")
    if let barcodeUri = challenge.barcodeUri {
        print("QR Code URI: \(barcodeUri)")
    }
    if let secret = challenge.secret {
        print("Secret: \(secret)")
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
    .enroll(mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("OTP enrollment initiated")
        if let barcodeUri = challenge.barcodeUri {
            print("QR Code URI: \(barcodeUri)")
        }
        if let secret = challenge.secret {
            print("Secret: \(secret)")
        }
    })
    .store(in: &cancellables)
```
</details>

#### Enroll push notification

Enroll Auth0 Guardian push notifications as an MFA factor.

```swift
Auth0
    .mfa()
    .enroll(mfaToken: mfaToken)
    .start { result in
        switch result {
        case .success(let challenge):
            print("Push notification enrollment initiated")
            if let barcodeUri = challenge.barcodeUri {
                print("QR Code URI: \(barcodeUri)")
                // Display this as a QR code for the user to scan with Guardian app
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
    let challenge = try await Auth0
        .mfa()
        .enroll(mfaToken: mfaToken)
        .start()
    print("Push notification enrollment initiated")
    if let barcodeUri = challenge.barcodeUri {
        print("QR Code URI: \(barcodeUri)")
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
    .enroll(mfaToken: mfaToken)
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { challenge in
        print("Push notification enrollment initiated")
        if let barcodeUri = challenge.barcodeUri {
            print("QR Code URI: \(barcodeUri)")
        }
    })
    .store(in: &cancellables)
```
</details>
