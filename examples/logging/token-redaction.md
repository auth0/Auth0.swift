### Automatic Token Redaction

**Security First**: Auth0.swift automatically redacts sensitive information from logs to protect user credentials. The following fields are redacted when logging HTTP responses:

- `access_token`
- `refresh_token`
- `id_token`

Redacted tokens appear as `"redacted"` in the logs, ensuring sensitive data never appears in plain text.
