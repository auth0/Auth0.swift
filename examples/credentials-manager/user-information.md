### Retrieve stored user information

The stored [ID token](https://auth0.com/docs/secure/tokens/id-tokens) contains a copy of the user information at the time of authentication (or renewal, if the credentials were renewed). That user information can be retrieved from the Keychain synchronously, without checking if the credentials expired.

```swift
do {
    let user = try credentialsManager.userProfile()
} catch {
    print("Failed to retrieve user profile: \(error)")
}
```

To get the latest user information, you can use the `renew()` [method](renew.md#renew-stored-credentials). Calling this method will automatically update the stored user information. You can also use the `userInfo(withAccessToken:)` [method](../authentication-api/user-information.md#retrieve-user-information) of the Authentication API client, but it will not update the stored user information.
