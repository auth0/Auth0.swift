### My Account API client errors

The My Account API client will only produce `MyAccountError` error values.

- The `info` property contains additional information about the error.
- The `cause` property contains the underlying error value, if any.
- Use the `isNetworkError` property to check if the request failed due to networking issues.
- Use the `isRetryable` property to check if the error represents a transient failure that can be retried (network errors, rate limiting, or server errors).

See the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/myaccounterror) to learn more about the available `MyAccountError` properties.

[Go up ⤴](../../EXAMPLES.md)
