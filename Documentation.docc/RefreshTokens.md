# Refresh Tokens: Common Errors

## Overview

Exchanging a refresh token for new credentials can produce the following errors, depending on the implementation of your app, and the configuration of your Auth0 application.

## Unknown or invalid refresh token

- **Example error description:** `The credentials renewal failed. CAUSE: Unknown or invalid refresh token`
- **Log event type:** `fertft`

This error means that Auth0 does not recognize the refresh token used to make the renewal request. Either an empty or garbage/truncated/padded token was sent, or the token is not valid anymore –it expired or was revoked.

### Common causes

#### Renewing the credentials after revoking the refresh token

If you revoke the refresh token –either through the Credentials Manager or the Authentication API client– you should not attempt to renew the credentials afterward. For example, by calling the `credentials()` method of the Credentials Manager in another thread.

Once a refresh token is revoked it can no longer be exchanged for new credentials.

#### Misconfiguration of the absolute lifetime of refresh tokens

The [absolute lifetime](https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-expiration) of the refresh token should not be shorter than the lifetime of the access token. If the access token is valid for longer than the refresh token is, your app may issue renewal requests with expired refresh tokens. This could happen, for example, when using the `credentials()` method of the Credentials Manager.

Once a refresh token expires it can no longer be exchanged for new credentials.

#### Misconfiguration of the inactivity lifetime of refresh tokens

The [inactivity lifetime](https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-expiration) of the refresh token should not be shorter than the lifetime of the access token. If the access token is valid for longer than the refresh token is *while the user is inactive*, your app may issue renewal requests with expired refresh tokens. This could happen, for example, when using the `credentials()` method of the Credentials Manager while your app is backgrounded. 

Once a refresh token expires due to user inactivity it can no longer be exchanged for new credentials.

## Unsuccessful Refresh Token exchange, reused refresh token detected

- **Example error description:** `The credentials renewal failed. CAUSE: Unsuccessful Refresh Token exchange, reused refresh token detected`
- **Log event type:** `ferrt`

You might encounter this error if you have [Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation) enabled for your Auth0 application. It means that the refresh token used to make the renewal request has already been exchanged, and the [reuse interval](https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-rotation) has passed.

Rotating refresh tokens are effectively single-use. The renewed credentials will come with a new refresh token, and the old one will be invalidated once the renew interval passes.

**In the absence of a bad actor, this error is typically a symptom of concurrency issues in your app.**

### Common causes

#### Multiple Credentials Manager instances

If you are using the Credentials Manager to renew the credentials -either through the `credentials()` or the `renew()` method- you should use a single Credentials Manager instance. While these methods are thread-safe, the Credentials Manager cannot synchronize them across instances.

This can happen, for example, by using a computed property to get a Credentials Manager instance:

```
struct Services {
    // ❌ This will return a new instance every time
    var credentialsManager: CredentialsManager {
        return CredentialsManager(authentication: Auth0.authentication())
    }
}
```

#### Using the Authentication API client to renew the credentials alongside the Credentials Manager

If you are using the Credentials Manager to store and retrieve the credentials, you should not force renewals through the `renew()` method of the Authentication API client. This method is not thread-safe, and may end up issuing renewal requests concurrently with the `credentials()` method of the Credentials Manager.

To force a renewal, use the ``CredentialsManager/renew(parameters:headers:callback:)`` method of the Credentials Manager instead. This method is thread-safe; the Credentials Manager will make sure only one renewal request is in flight at any given time.

#### Using the Authentication API client to renew the credentials without synchronization

If you are *not* using the Credentials Manager, you need to implement proper synchronization to call the `renew()` method of the Authentication API client. This method is not thread-safe; unless care is taken, concurrent renewal requests can happen.
