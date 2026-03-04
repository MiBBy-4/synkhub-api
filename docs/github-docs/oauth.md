# GitHub OAuth Flow

> For step-by-step setup instructions, see [setup-guide.md](setup-guide.md).

## Overview

GitHub OAuth allows users to connect their GitHub account to SynkHub so we can map events to them.

## Flow

1. **Redirect** — send user to `https://github.com/login/oauth/authorize` with query params
2. **Callback** — GitHub redirects back with a `code` query param
3. **Exchange** — POST the code to `https://github.com/login/oauth/access_token` to get an access token
4. **User info** — GET `https://api.github.com/user` with `Authorization: Bearer <token>`

## Authorization URL Parameters

| Parameter      | Description                                    |
|----------------|------------------------------------------------|
| `client_id`    | OAuth app client ID (from GitHub settings)     |
| `redirect_uri` | Where GitHub sends the user after authorization|
| `scope`        | Space-separated list of requested permissions  |
| `state`        | Random CSRF token — **must** be validated       |

Example:

```
https://github.com/login/oauth/authorize?client_id=abc&redirect_uri=http://localhost:5173/github/callback&scope=repo+read:user&state=random_token
```

## Token Exchange

```
POST https://github.com/login/oauth/access_token
Accept: application/json
Content-Type: application/json

{
  "client_id": "...",
  "client_secret": "...",
  "code": "code_from_callback"
}
```

Response:

```json
{
  "access_token": "gho_xxxxxxxxxxxx",
  "token_type": "bearer",
  "scope": "repo,read:user,user:email,notifications,admin:repo_hook"
}
```

## User Info

```
GET https://api.github.com/user
Authorization: Bearer gho_xxxxxxxxxxxx
```

Response includes `id`, `login`, `email`, `name`, `avatar_url`, etc.

## Recommended Scopes

| Scope              | Reason                                      |
|--------------------|---------------------------------------------|
| `repo`             | Access to repo events (PRs, issues, pushes) |
| `read:user`        | Read user profile data                      |
| `user:email`       | Access user email addresses                 |
| `notifications`    | Read GitHub notifications                   |
| `admin:repo_hook`  | Create/manage webhooks on repos             |

## Security

- **Validate `state` param** — store a random token in cache before redirect, verify it on callback to prevent CSRF
- **Store tokens encrypted** — use Rails `encrypts` for `github_access_token`
- **Codes expire** — authorization codes are single-use and expire in 10 minutes
- **Use HTTPS** in production redirect URIs
