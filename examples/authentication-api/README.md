## Authentication API (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/authentication)**

> [!NOTE]
> All completion callbacks in Auth0.swift execute on the main thread, making it safe to update UI directly. If needed, explicitly dispatch to a background thread.

- [Log in with database connection](login-database.md#log-in-with-database-connection)
- [Sign up with database connection](signup-database.md#sign-up-with-database-connection)
- [Reset a password](reset-password.md#reset-a-password)
- [Log in with passkey [EA]](login-passkey.md#log-in-with-passkey-ea)
- [Sign up with passkey [EA]](signup-passkey.md#sign-up-with-passkey-ea)
- [Passwordless login](passwordless.md#passwordless-login)
- [Passwordless login with a database connection [EA]](passwordless-database.md#passwordless-login-with-a-database-connection-ea)
- [Retrieve user information](user-information.md#retrieve-user-information)
- [Renew credentials](renew-credentials.md#renew-credentials)
- [Get SSO credentials](sso-credentials.md#get-sso-credentials)
- [DPoP](dpop.md#dpop)
- [Authentication API client configuration](configuration.md#authentication-api-client-configuration)
- [Authentication API client errors](errors.md#authentication-api-client-errors)

The Authentication API exposes the AuthN/AuthZ functionality of Auth0, as well as the supported identity protocols like OpenID Connect, OAuth 2.0, and SAML.
We recommend using [Universal Login](https://auth0.com/docs/authenticate/login/auth0-universal-login), but if you prefer to build your own UI you can use our API endpoints to do so. However, some Auth flows (grant types) are disabled by default so you must enable them in the settings page of your [Auth0 application](https://manage.auth0.com/#/applications/), as explained in [Update Grant Types](https://auth0.com/docs/get-started/applications/update-grant-types).

For login or signup with username/password, the `Password` grant type needs to be enabled in your Auth0 application. If you set the grants via the Management API you should activate both `http://auth0.com/oauth/grant-type/password-realm` and `Password`. Otherwise, the Auth0 Dashboard will take care of activating both when enabling `Password`.

> [!NOTE] 
> If your Auth0 tenant has the **Bot Detection** feature enabled, your requests might be flagged for verification. Check how to handle this scenario in the [Bot Detection](../advanced-features/bot-detection.md#bot-detection) section.

> [!WARNING]
> The ID tokens obtained from Web Auth login are automatically validated by Auth0.swift, ensuring their contents have not been tampered with. **This is not the case for the ID tokens obtained from the Authentication API client**, including the ones received when renewing the credentials using the refresh token. You must [validate](https://auth0.com/docs/secure/tokens/id-tokens/validate-id-tokens) any ID tokens received from the Authentication API client before using the information they contain.
