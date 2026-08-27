### Credentials Manager errors

The Credentials Manager will only produce `CredentialsManagerError` error values. You can find the underlying error (if any) in the `cause: Error?` property of the `CredentialsManagerError`. Not all error cases will have an underlying `cause`. Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanagererror) to learn more about the error cases you need to handle, and which ones include a `cause` value.

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
    case .failure(let error):
        switch error {
        case CredentialsManagerError.noCredentials:
            // No credentials stored — prompt login
            break
        case CredentialsManagerError.noRefreshToken:
            // Credentials expired and no refresh token — prompt login
            break
        case CredentialsManagerError.renewFailed:
            // Token renewal failed — check error.cause for details
            break
        case CredentialsManagerError.storeFailed:
            // Failed to save renewed credentials to Keychain
            break
        case CredentialsManagerError.clearFailed:
            // Failed to remove credentials from Keychain
            break
        case CredentialsManagerError.biometricsFailed:
            // Biometric authentication failed — check error.cause for details
            break
        case CredentialsManagerError.revokeFailed:
            // Token revocation failed — check error.cause for details
            break
        case CredentialsManagerError.sessionExpired:
            // Upstream IdP session ceiling reached — prompt re-login
            break
        default:
            break
        }
    }
}
```

To revoke the stored refresh token and clear credentials, use the `revoke()` method:

```swift
credentialsManager.revoke { result in
    switch result {
    case .success:
        // Refresh token revoked and credentials cleared
        break
    case .failure(let error):
        switch error {
        case CredentialsManagerError.noCredentials:
            // No credentials in storage — nothing to revoke
            break
        case CredentialsManagerError.revokeFailed:
            // Network revocation failed — the refresh token may still be active
            break
        case CredentialsManagerError.clearFailed:
            // Token was revoked but credentials could not be removed from storage
            break
        default:
            break
        }
    }
}
```

#### DPoP error handling

When using DPoP with the Credentials Manager, additional validation is performed on credential retrieval to ensure the DPoP key pair is consistent. The following errors may be returned:

- **`dpopNotConfigured`**: The stored credentials are DPoP-bound but the `Authentication` client was not configured with DPoP via `.useDPoP()`. Ensure the `Authentication` client used by the `CredentialsManager` has DPoP enabled.

- **`dpopKeyMissing`**: The DPoP key pair is no longer available in the Keychain (e.g., due to app reinstall or Keychain reset). Stored credentials are cleared automatically. The user must log in again.

- **`dpopKeyMismatch`**: The current DPoP key pair does not match the one used when the credentials were saved. Stored credentials are cleared automatically. The user must log in again.

```swift
credentialsManager.credentials { result in
    switch result {
    case .success(let credentials):
        print("Obtained credentials: \(credentials)")
    case .failure(let error):
        switch error {
        case .dpopNotConfigured:
            // Authentication client was not configured with .useDPoP().
            // Fix the CredentialsManager initialisation:
            //   CredentialsManager(authentication: Auth0.authentication().useDPoP())
            break
        case .dpopKeyMissing:
            // DPoP key was lost (e.g. app reinstall). Prompt user to re-authenticate.
            break
        case .dpopKeyMismatch:
            // DPoP key doesn't match the one used at login. Prompt user to re-authenticate.
            break
        default:
            print("Failed with: \(error)")
        }
    }
}
```

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Run a switch statement on the [error cases](https://auth0.github.io/Auth0.swift/documentation/auth0/credentialsmanagererror/#topics) instead, which are part of the API.

[Go up ⤴](../../EXAMPLES.md)
