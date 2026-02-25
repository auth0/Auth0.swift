# v3 Migration Guide

> **Note:** This guide is actively maintained during the v3 development phase. As new changes are merged, this document will be updated to reflect the latest breaking changes and migration steps.

Auth0.swift v3 includes many significant changes:

- Updated default values for better out-of-the-box behavior.
- Behavior changes to improve developer experience:
  - Consistent main thread callback execution for UI updates.
- Methods added for supporting new features


As expected with a major release, Auth0.swift v3 contains breaking changes. Please review this guide thoroughly to understand the changes required to migrate your application to v3.

---

## Table of Contents

- [**Default Values Changed**](#default-values-changed)
  + [Scope](#scope)
  + [Credentials Manager minTTL](#credentials-manager-minttl)
  + [Signup connection](#signup-connection)
- [**Behavior Changes**](#behavior-changes)
  + [Completion callbacks](#completion-callbacks)
- [**Methods Added**](#methods-added)
  + [Web Auth](#web-auth)
- [**API Changes**](#api-changes)
  + [WebAuthError cases](#webautherror-cases)

---

## Default Values Changed

### Scope

**Change:** The default scope value now includes `offline_access`.

The default scope value was changed from `openid profile email` to `openid profile email offline_access`. This change applies to Web Auth and all Authentication client methods (except `renew(withRefreshToken:scope:)`, in which `scope` keeps defaulting to `nil`).

**Impact:** If your application doesn't need refresh tokens, you should explicitly specify the scope without `offline_access`.

<details>
  <summary>Migration example</summary>

```swift
// v2 - offline_access had to be explicitly added
Auth0
    .webAuth()
    .scope("openid profile email offline_access")
    .start { result in
        // ...
    }

// v3 - offline_access is included by default
Auth0
    .webAuth()
    .start { result in
        // ...
    }

// v3 - opt out of offline_access if not needed
Auth0
    .webAuth()
    .scope("openid profile email")
    .start { result in
        // ...
    }
```
</details>

**Reason:** Mobile apps typically rely on refresh tokens to maintain user sessions over extended periods. Since default values should reflect the most common usage scenarios, the default scope now includes `offline_access`.

### Credentials Manager minTTL

**Change:** The default `minTTL` value changed from `0` to `60` seconds.

This change affects the following Credentials Manager methods:

- `credentials(withScope:minTTL:parameters:headers:callback:)`
- `credentials(withScope:minTTL:parameters:headers:)` (async/await)
- `credentials(withScope:minTTL:parameters:headers:)` (Combine)
- `apiCredentials(forAudience:scope:minTTL:parameters:headers:callback:)`
- `apiCredentials(forAudience:scope:minTTL:parameters:headers:)` (async/await)
- `apiCredentials(forAudience:scope:minTTL:parameters:headers:)` (Combine)

**Impact:** Credentials will be renewed if they expire within 60 seconds, instead of only when already expired.

<details>
  <summary>Migration example</summary>

```swift
// v2 - minTTL defaulted to 0, had to be set explicitly
credentialsManager.credentials(minTTL: 60) { result in
    // ...
}

// v3 - minTTL defaults to 60 seconds
credentialsManager.credentials { result in
    // ...
}

// v3 - use 0 to restore v2 behavior
credentialsManager.credentials(minTTL: 0) { result in
    // ...
}
```
</details>

**Reason:** A `minTTL` of `0` meant credentials were not renewed until expired, which could result in delivering access tokens that expire immediately after retrieval, causing subsequent API requests to fail. Setting a default value of `60` seconds ensures the access token remains valid for a reasonable period.

### Signup connection

**Change:** The `connection` parameter now defaults to `"Username-Password-Authentication"`.

This change affects the following Authentication client method:

- `signup(email:username:password:connection:userMetadata:rootAttributes:)`

**Impact:** You no longer need to specify the connection parameter if you're using the default database connection.

<details>
  <summary>Migration example</summary>

```swift
// v2 - connection had to be specified
Auth0
    .authentication()
    .signup(email: email,
            username: username,
            password: password,
            connection: "Username-Password-Authentication")
    .start { result in
        // ...
    }

// v3 - connection parameter is optional
Auth0
    .authentication()
    .signup(email: email,
            username: username,
            password: password)
    .start { result in
        // ...
    }

// v3 - specify connection if using a different one
Auth0
    .authentication()
    .signup(email: email,
            username: username,
            password: password,
            connection: "custom-database")
    .start { result in
        // ...
    }
```
</details>

**Reason:** By default, new Auth0 tenants have a database connection called `Username-Password-Authentication`. Since it's the default database connection name that many customers use, having it as the default reduces boilerplate.

## Behavior Changes

### Completion callbacks

**Change:** All completion callbacks now execute on the main thread.

In v2, completion callbacks would sometimes execute on the main thread and sometimes on background threads, depending on where `URLSession` completed the network request. In v3, all completion callbacks are guaranteed to execute on the main thread.

**Affected APIs:**

- All Authentication and Management API methods using callbacks
- All Credentials Manager methods using callbacks
- All Web Auth methods using callbacks

**Impact:** If your code performs CPU-intensive work in callbacks, you should explicitly dispatch to a background queue.

<details>
  <summary>Migration example</summary>

```swift
// v2 - thread was unpredictable, had to dispatch to main for UI updates
credentialsManager.credentials { result in
    DispatchQueue.main.async {
        self.updateUI(result)
    }
}

// v3 - already on main thread
credentialsManager.credentials { result in
    self.updateUI(result)
}

// v3 - dispatch to background for CPU-intensive work
credentialsManager.credentials { result in
    DispatchQueue.global().async {
        let processed = self.performExpensiveOperation(result)
        DispatchQueue.main.async {
            self.updateUI(processed)
        }
    }
}
```
</details>

**Reason:** After performing operations with Auth0.swift, it's common to run presentation logic – for example, to show an error or navigate to the main flow of the app. Having callbacks execute on the main thread by default improves developer experience and reduces boilerplate.

## Methods Added

### Web Auth

Auth0.swift will use a current key window to present the in-app browser for Web Auth. When using ASWebAuthenticationSession, it will grab a key window and use it as the ASPresentationAnchor. With SFSafariViewController, Auth0.swift will present it using the topmost view controller in this key window. While this approach works well for single-window apps, on multi-window apps the in-app browser may show up in a different window than expected. Auth0.swift now supports passing a custom window in which to present the in-app browser. For this reason, the following method is added to the Web Auth builder:

- `presentationWindow(_ window:)`

<details>
  <summary>Code</summary>

```swift
Auth0
    .webAuth()
    .presentationWindow(window)
    .start { result in
        // ...
    }
```
</details>

---

## API Changes

### WebAuthError cases

**Change:** WebAuthError has been refined to provide more actionable error information:

**Removed cases** (now return `.unknown` with descriptive messages):
- `.noBundleIdentifier` - Configuration error that should be caught during development
- `.noAuthorizationCode` - Rare edge case in PKCE flow
- `.invalidInvitationURL` - Configuration error for organization invitations
- `.pkceNotAllowed` - Configuration error (Application Type must be "Native" and Token Endpoint Authentication Method must be "None"). This error happens at most once when integrating the SDK into the app

**New cases**:
- `.authenticationFailed` - Server-side authentication failures (wrong password, MFA required, account locked, etc.)
- `.codeExchangeFailed` - Token exchange failures (network issues, invalid grant, backend errors, etc.)

**Impact:** Error handling code needs to be updated to use the new error cases. The removed cases will now throw `.unknown` errors with descriptive messages.

**Reason:** The removed error cases represent configuration issues that should be caught during development, not handled in production code. This will result in a more useful and meaningful set of WebAuthError cases.

---
[Go up ⤴](#table-of-contents)
