### Passwordless login

Passwordless is a two-step authentication flow that requires the **Passwordless OTP** grant to be enabled for your Auth0 application. Check [our documentation](https://auth0.com/docs/get-started/applications/application-grant-types) for more information.

#### 1. Start the passwordless flow

Request a code to be sent to the user's email or phone number. For email scenarios, a link can be sent in place of the code.

```swift
Auth0
    .authentication()
    .startPasswordless(email: "support@auth0.com")
    .start { result in
        switch result {
        case .success:
            print("Code sent")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    try await Auth0
        .authentication()
        .startPasswordless(email: "support@auth0.com")
        .start()
    print("Code sent")
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
    .startPasswordless(email: "support@auth0.com")
    .start()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Code sent")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }, receiveValue: {})
    .store(in: &cancellables)
```
</details>

> [!NOTE]
> Use `startPasswordless(phoneNumber:)` to send a code to the user's phone number instead.

#### 2. Login with the received code

To complete the authentication, you must send back that code the user received along with the email or phone number used to start the flow.

```swift
Auth0
    .authentication()
    .login(email: "support@auth0.com", code: "123456")
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
        .login(email: "support@auth0.com", code: "123456")
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
    .login(email: "support@auth0.com", code: "123456")
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
> Use `login(phoneNumber:code:)` if the code was sent to the user's phone number.
