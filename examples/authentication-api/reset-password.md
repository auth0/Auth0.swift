### Reset a password

Send a password reset email to a database user.

```swift
Auth0
    .authentication()
    .resetPassword(email: "support@auth0.com",
                   connection: "Username-Password-Authentication")
    .start { result in
        switch result {
        case .success:
            print("Password reset email sent")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

If the user belongs to an [organization](../advanced-features/organizations.md#organizations), pass its identifier to associate the reset request with that organization. Auth0 then includes the `organization_id` and `organization_name` values in the password reset redirect URL, and makes them available as variables in customized email templates.

```swift
Auth0
    .authentication()
    .resetPassword(email: "support@auth0.com",
                   connection: "Username-Password-Authentication",
                   organization: "org_abc123") // 👈🏼
    .start { result in
        switch result {
        case .success:
            print("Password reset email sent")
        case .failure(let error):
            print("Failed with: \(error)")
        }
    }
```

> [!NOTE]
> The `organization` value must be the organization ID (for example, `org_abc123`), not the organization name. It is optional; pass `nil` to omit it.

<details>
  <summary>Using async/await</summary>

```swift
do {
    try await Auth0
        .authentication()
        .resetPassword(email: "support@auth0.com",
                       connection: "Username-Password-Authentication",
                       organization: "org_abc123")
        .start()
    print("Password reset email sent")
} catch {
    print("Failed with: \(error)")
}
```
</details>

<details>
  <summary>Using Combine</summary>

```swift
Auth0
    .authentication()
    .resetPassword(email: "support@auth0.com",
                   connection: "Username-Password-Authentication",
                   organization: "org_abc123")
    .start()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Failed with: \(error)")
        }
    }, receiveValue: { _ in
        print("Password reset email sent")
    })
    .store(in: &cancellables)
```
</details>
