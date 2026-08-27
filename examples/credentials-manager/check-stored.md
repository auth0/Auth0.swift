### Check for stored credentials

When the users open your app, check for stored credentials. If they exist and are valid / can be renewed, you can retrieve them and redirect the users to the app's main flow without any additional login steps.

#### If you are using refresh tokens

```swift
guard credentialsManager.canRenew() else {
    // No renewable credentials exist, present the login page
}
// Retrieve the stored credentials
```

See [Get a refresh token](../web-auth/configuration.md#get-a-refresh-token) to learn how to obtain a [refresh token](https://auth0.com/docs/secure/tokens/refresh-tokens).

#### If you are not using refresh tokens

```swift
guard credentialsManager.hasValid() else {
    // No valid credentials exist, present the login page
}
// Retrieve the stored credentials
```
