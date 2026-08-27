### DPoP [EA]

[DPoP](https://www.rfc-editor.org/rfc/rfc9449.html) (Demonstrating Proof of Possession) is an application-level mechanism for sender-constraining OAuth 2.0 access and refresh tokens by proving that the app is in possession of a certain private key. You can enable it by calling the `useDPoP()` method.

```swift
Auth0
    .webAuth()
    .useHTTPS()
    .useDPoP()
    .start { result in
        switch result {
        case .success(let credentials):
            print("Obtained credentials: \(credentials)")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

> [!IMPORTANT]
> DPoP will only be used for new user sessions created after enabling it. DPoP **will not** be applied to any requests involving existing access and refresh tokens (such as exchanging the refresh token for new credentials).
>
> This means that, after you've enabled it in your app, DPoP will only take effect when users log in again. It's up to you to decide how to roll out this change to your users. For example, you might require users to log in again the next time they open your app. You'll need to implement the logic to handle this transition based on your app's requirements.

When making requests to your own APIs, use the `DPoP.addHeaders()` method to add the `Authorization` and `DPoP` headers to a `URLRequest`. The `Authorization` header is set using the access token and token type, while the `DPoP` header contains the generated DPoP proof.

```swift
var request = URLRequest(url: URL(string: "https://example.com/api/endpoint")!)
request.httpMethod = "POST"

try DPoP.addHeaders(to: &request,
                    accessToken: credentials.accessToken,
                    tokenType: credentials.tokenType)
```

If your API is issuing DPoP nonces to prevent replay attacks, you can pass the nonce value to the `addHeaders()` method to include it in the DPoP proof. Use the `DPoP.isNonceRequired(by:)` method to check if a particular API response failed because a nonce is required.

```swift
if DPoP.isNonceRequired(by: response), 
    let nonce = response.value(forHTTPHeaderField: "DPoP-Nonce") {
    try DPoP.addHeaders(to: &request,
                        accessToken: credentials.accessToken,
                        tokenType: credentials.tokenType,
                        nonce: nonce)

    // Retry the request with the new DPoP proof that includes the nonce
}
```

On logout, you should call `DPoP.clearKeypair()` to delete the user's key pair from the Keychain.

```swift
Auth0.webAuth()
    .useHTTPS()
    .logout { result in
    // ...
}

try credentialsManager.clear()
try DPoP.clearKeypair()
```

> [!NOTE]  
> When logging out, you do not need to call `useDPoP()` as it has no effect during the logout process.
