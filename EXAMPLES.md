# Examples

Each feature lives in its own file under [`examples/`](examples).

## [Web Auth (iOS / macOS / visionOS)](examples/web-auth.md)

- [Web Auth signup](examples/web-auth.md#web-auth-signup)
- [Web Auth configuration](examples/web-auth.md#web-auth-configuration)
- [ID token validation](examples/web-auth.md#id-token-validation)
- [DPoP](examples/web-auth.md#dpop)
- [Automatic credentials management](examples/web-auth.md#automatic-credentials-management)
- [Web Auth errors](examples/web-auth.md#web-auth-errors)

## [Credentials Manager (iOS / macOS / tvOS / watchOS / visionOS)](examples/credentials-manager.md)

- [Store credentials](examples/credentials-manager.md#store-credentials)
- [Check for stored credentials](examples/credentials-manager.md#check-for-stored-credentials)
- [Retrieve stored credentials](examples/credentials-manager.md#retrieve-stored-credentials)
- [Renew stored credentials](examples/credentials-manager.md#renew-stored-credentials)
- [Retrieve stored user information](examples/credentials-manager.md#retrieve-stored-user-information)
- [Clear stored credentials](examples/credentials-manager.md#clear-stored-credentials)
- [Clear all stored credentials](examples/credentials-manager.md#clear-all-stored-credentials)
- [Biometric authentication](examples/credentials-manager.md#biometric-authentication)
- [IPSIE session expiry [EA]](examples/credentials-manager.md#ipsie-session-expiry-ea)
- [Other credentials](examples/credentials-manager.md#other-credentials)
- [Credentials Manager errors](examples/credentials-manager.md#credentials-manager-errors)

## [Authentication API (iOS / macOS / tvOS / watchOS / visionOS)](examples/authentication-api/README.md)

- [Log in with database connection](examples/authentication-api/login-database.md)
- [Sign up with database connection](examples/authentication-api/signup-database.md)
- [Reset a password](examples/authentication-api/reset-password.md)
- [Log in with passkey](examples/authentication-api/login-passkey.md)
- [Sign up with passkey](examples/authentication-api/signup-passkey.md)
- [Passwordless login](examples/authentication-api/passwordless.md)
- [Passwordless login with a database connection [EA]](examples/authentication-api/passwordless-database.md)
- [Retrieve user information](examples/authentication-api/user-information.md)
- [Renew credentials](examples/authentication-api/renew-credentials.md)
- [Get SSO credentials](examples/authentication-api/sso-credentials.md)
- [DPoP](examples/authentication-api/dpop.md)
- [Authentication API client configuration](examples/authentication-api/configuration.md)
- [Authentication API client errors](examples/authentication-api/errors.md)

## [MFA API (iOS / macOS / tvOS / watchOS / visionOS)](examples/mfa-api.md)

- [Prerequisites](examples/mfa-api.md#prerequisites)
- [Handling MFA required errors](examples/mfa-api.md#handling-mfa-required-errors)
- [Get available authenticators](examples/mfa-api.md#get-available-authenticators)
- [Enroll MFA factors](examples/mfa-api.md#enroll-mfa-factors)
- [Challenge an enrolled authenticator](examples/mfa-api.md#challenge-an-enrolled-authenticator)
- [Verify MFA](examples/mfa-api.md#verify-mfa)
- [Complete MFA flow examples](examples/mfa-api.md#complete-mfa-flow-examples)
- [MFA client configuration](examples/mfa-api.md#mfa-client-configuration)
- [MFA client errors](examples/mfa-api.md#mfa-client-errors)

## [My Account API (iOS / macOS / tvOS / watchOS / visionOS)](examples/my-account-api.md)

- [Enroll a new passkey](examples/my-account-api.md#enroll-a-new-passkey)
- [Enroll a new email authentication method](examples/my-account-api.md#enroll-a-new-email-authentication-method)
- [Enroll a new phone authentication method](examples/my-account-api.md#enroll-a-new-phone-authentication-method)
- [Enroll a new TOTP authentication method](examples/my-account-api.md#enroll-a-new-totp-authentication-method)
- [Enroll a new push notification authentication method](examples/my-account-api.md#enroll-a-new-push-notification-authentication-method)
- [Enroll a new recovery code authentication method](examples/my-account-api.md#enroll-a-new-recovery-code-authentication-method)
- [Enroll a new password authentication method](examples/my-account-api.md#enroll-a-new-password-authentication-method)
- [Get all factors](examples/my-account-api.md#get-all-factors)
- [Get all authentication methods](examples/my-account-api.md#get-all-authentication-methods)
- [Get an authentication method by id](examples/my-account-api.md#get-an-authentication-method-by-id)
- [Delete an authentication method](examples/my-account-api.md#delete-an-authentication-method)
- [My Account API client errors](examples/my-account-api.md#my-account-api-client-errors)

## [Logging](examples/logging.md)

- [Enable Logging](examples/logging.md#enable-logging)
- [Automatic Token Redaction](examples/logging.md#automatic-token-redaction)
- [Logging Output](examples/logging.md#logging-output)
- [Viewing Logs](examples/logging.md#viewing-logs)

## [Advanced Features](examples/advanced-features/README.md)

- [Native social login](examples/advanced-features/native-social-login.md)
- [Custom Token Exchange](examples/advanced-features/custom-token-exchange.md)
- [Organizations](examples/advanced-features/organizations.md)
- [Bot Detection](examples/advanced-features/bot-detection.md)
