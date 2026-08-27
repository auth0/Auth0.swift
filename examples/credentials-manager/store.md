### Store credentials

When your users log in, store their credentials securely in the Keychain. You can then check if their credentials are still valid when they open your app again.

```swift
do {
    try credentialsManager.store(credentials: credentials)
} catch {
    print("Failed to store credentials: \(error)")
}
```
