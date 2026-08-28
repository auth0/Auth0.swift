### Authentication API client errors

The Authentication API client will only produce `AuthenticationError` error values.

- The `info` property contains additional information about the error.
- The `cause` property contains the underlying error value, if any.
- Use the `isNetworkError` property to check if the request failed due to networking issues.
- Use the `isRetryable` property to check if the error represents a transient failure that can be retried (network errors, rate limiting, or server errors).

Check the [API documentation](https://auth0.github.io/Auth0.swift/documentation/auth0/authenticationerror) to learn more about the available `AuthenticationError` properties.

> [!WARNING]
> Do not parse or otherwise rely on the error messages to handle the errors. The error messages are not part of the API and can change. Use the [error types](https://auth0.github.io/Auth0.swift/documentation/auth0/authenticationerror/#topics) instead, which are part of the API.

[Go up ⤴](../../EXAMPLES.md#examples)
