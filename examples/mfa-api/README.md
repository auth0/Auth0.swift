## MFA API (iOS / macOS / tvOS / watchOS / visionOS)

**See all the available features in the [API documentation ↗](https://auth0.github.io/Auth0.swift/documentation/auth0/mfaclient)**

- [Handling MFA required errors](handling-mfa-required.md#handling-mfa-required-errors)
- [Get available authenticators](get-authenticators.md#get-available-authenticators)
- [Enroll MFA factors](enroll.md#enroll-mfa-factors)
  - [Enroll SMS](enroll.md#enroll-sms)
  - [Enroll email](enroll.md#enroll-email)
  - [Enroll OTP (TOTP)](enroll.md#enroll-otp-totp)
  - [Enroll push notification](enroll.md#enroll-push-notification)
- [Challenge an enrolled authenticator](challenge.md#challenge-an-enrolled-authenticator)
- [Verify MFA](verify.md#verify-mfa)
  - [Verify with OOB code](verify.md#verify-with-oob-code)
  - [Verify with OTP code](verify.md#verify-with-otp-code)
  - [Verify with recovery code](verify.md#verify-with-recovery-code)
- [Complete MFA flow examples](complete-flows.md#complete-mfa-flow-examples)
- [MFA client configuration](configuration.md#mfa-client-configuration)
- [MFA client errors](errors.md#mfa-client-errors)

The MFA API allows you to implement multi-factor authentication flows using the Auth0 Authentication API. This includes enrolling MFA factors, challenging enrolled factors, and verifying MFA codes.

> [!NOTE]
> The MFA API requires specific grant types to be enabled in your Auth0 application. Check the [Dashboard](https://manage.auth0.com/#/applications/) under **Application Settings > Advanced Settings > Grant Types**.
