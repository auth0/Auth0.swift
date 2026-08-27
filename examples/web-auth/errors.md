### Web Auth errors

Web Auth will only produce `WebAuthError` error values. You can find the underlying error (if any) in the `cause: Error?` property of the `WebAuthError`. Not all error cases will have an underlying `cause`. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/webautherror) to learn more about the error cases you need to handle, and which ones include a `cause` value.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Run a switch statement on the [error cases](https://auth0.github.io/Auth0.swift/documentation/auth0/webautherror/#topics) instead, which are part of the API.

#### Error handling example

```swift
Auth0
    .webAuth()
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
            
        case .failure(let error):
            switch error {
            case .userCancelled:
                // User pressed the "Cancel" button
                print("User cancelled")
                
            case .authenticationFailed:
                // Authentication failed on the server side
                // Access the underlying AuthenticationError for details
                if let authError = error.cause as? AuthenticationError {
                    print("Auth failed: \(authError.info["error"] ?? "unknown")")
                }
                
            case .codeExchangeFailed:
                // Token exchange failed 
                if let authError = error.cause as? AuthenticationError {
                    print("Token exchange failed: \(authError.info["error"] ?? "unknown")")
                }
                
            case .unknown(let message):
                // Configuration errors or unexpected issues
                print("Unknown error: \(message)")
                
            default:
                print("Error: \(error)")
            }
        }
    }
```

<details>
  <summary>Using async/await</summary>

```swift
do {
    let credentials = try await Auth0.webAuth().start()
    print("Obtained credentials: \(credentials)")
} catch let error as WebAuthError {
    switch error {
    case .userCancelled:
        print("User cancelled")
    case .authenticationFailed:
        if let authError = error.cause as? AuthenticationError {
            print("Auth failed: \(authError.info["error"] ?? "unknown")")
        }
    case .codeExchangeFailed:
        if let authError = error.cause as? AuthenticationError {
            print("Token exchange failed: \(authError.info["error"] ?? "unknown")")
        }
    case .unknown(let message):
        print("Unknown error: \(message)")
    default:
        print("Error: \(error)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .webAuth()
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            switch error {
            case .userCancelled:
                print("User cancelled")
            case .authenticationFailed:
                if let authError = error.cause as? AuthenticationError {
                    print("Auth failed: \(authError.info["error"] ?? "unknown")")
                }
            case .codeExchangeFailed:
                if let authError = error.cause as? AuthenticationError {
                    print("Token exchange failed: \(authError.info["error"] ?? "unknown")")
                }
            case .unknown(let message):
                print("Unknown error: \(message)")
            default:
                print("Error: \(error)")
            }
        }
    }, receiveValue: { credentials in
        print("Obtained credentials: \(credentials)")
    })
    .store(in: &cancellables)
```
</details>

[Go up ⤴](../../EXAMPLES.md)
