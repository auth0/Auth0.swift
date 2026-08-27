### Clear all stored credentials

To remove **all** credentials stored by the Credentials Manager from the Keychain —including the default credentials entry and any API credentials stored for different audiences— use the `clearAll()` method.

```swift
do {
    try credentialsManager.clearAll()
} catch {
    print("Failed to clear all credentials: \(error)")
}
```

> [!NOTE]
> `clearAll()` delegates to the underlying storage's `deleteAllEntries()` method, which removes all entries for the configured service/access group. Ensure the storage is dedicated to Auth0 credentials to avoid unintended data loss.

This is different from `clear()`, which only removes the default credentials entry.
