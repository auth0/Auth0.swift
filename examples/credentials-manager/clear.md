### Clear stored credentials

The stored credentials can be removed from the Keychain by using the `clear()` method.

```swift
do {
    try credentialsManager.clear()
} catch {
    print("Failed to clear credentials: \(error)")
}
```
