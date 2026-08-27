### Logging Output

With logging enabled, you'll see detailed HTTP request and response information. Here's an example of what a successful authentication flow looks like:

```text
ASWebAuthenticationSession: https://example.us.auth0.com/authorize?.....
Callback URL: com.example.MyApp://example.us.auth0.com/ios/com.example.MyApp/callback?...

POST https://example.us.auth0.com/oauth/token HTTP/1.1
Content-Type: application/json
Auth0-Client: eyJ2ZXJzaW9uI...

{
  "code": "...",
  "client_id": "...",
  "grant_type": "authorization_code",
  "redirect_uri": "com.example.MyApp://example.us.auth0.com/ios/com.example.MyApp/callback",
  "code_verifier": "..."
}

HTTP/1.1 200
Pragma: no-cache
Content-Type: application/json
Strict-Transport-Security: max-age=3600
Date: Wed, 08 Dec 2025 10:30:00 GMT
Content-Length: 1024
Cache-Control: no-cache
Connection: keep-alive

{
  "access_token": "redacted",
  "refresh_token": "redacted",
  "id_token": "redacted",
  "token_type": "Bearer",
  "expires_in": 86400
}
```
