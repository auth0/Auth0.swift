### Biometric authentication

You can enable an additional level of user authentication before retrieving credentials using the biometric authentication supported by the device, such as Face ID or Touch ID.

```swift
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID")
```

If needed, you can specify a particular `LAPolicy` to be used. For example, you might want to support Face ID or Touch ID, but also allow fallback to passcode.

```swift
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID or passcode", 
                                    evaluationPolicy: .deviceOwnerAuthentication)
```

#### Biometric Policy

You can configure a `BiometricPolicy` to control when biometric authentication is required. There are four types of policies available:

- **`.default`**: Uses the same `LAContext` instance, allowing the system to manage biometric prompts. The system may skip the prompt if biometric authentication was recently successful. This is the default policy and preserves backward-compatible behavior.
- **`.always`**: Requires biometric authentication every time credentials are accessed. Creates a fresh `LAContext` for each authentication to ensure a new prompt is always shown.
- **`.session(timeoutInSeconds:)`**: Requires biometric authentication only if the specified time (in seconds) has passed since the last successful authentication. Creates a fresh `LAContext` when the session has expired.
- **`.appLifecycle(timeoutInSeconds:)`**: Similar to the session policy, but the session persists for the lifetime of the app process. Creates a fresh `LAContext` when the session has expired. The default timeout is 1 hour (3600 seconds).

> [!NOTE]
> The `.always`, `.session`, and `.appLifecycle` policies create a new `LAContext` for each authentication attempt (when required), ensuring that the biometric prompt is shown reliably. The `.default` policy reuses the same context, which allows the system to optimize prompt frequency.

**Examples:**

```swift
// Default behavior - system manages biometric prompts (default)
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .default)

// Always require biometric authentication with fresh prompt
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .always)

// Require authentication only once per 5-minute session
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .session(timeoutInSeconds: 300))

// Require authentication once per app lifecycle (1 hour default)
credentialsManager.enableBiometrics(withTitle: "Unlock with Face ID",
                                    policy: .appLifecycle()) // Default: 3600 seconds (1 hour)
```

**Managing Biometric Sessions:**

You can manually clear the biometric session to force re-authentication on the next credential access:

```swift
// Clear the biometric session
credentialsManager.clearBiometricSession()

// Check if the current session is valid
let isValid = credentialsManager.isBiometricSessionValid()
```

> [!NOTE]
> Retrieving the user information with `credentialsManager.userProfile()` will not be protected by biometric authentication.
