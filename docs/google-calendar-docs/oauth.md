# Google Calendar OAuth 2.0 Flow

> Reference: [Using OAuth 2.0 for Web Server Applications](https://developers.google.com/identity/protocols/oauth2/web-server)

## Overview

Google Calendar uses OAuth 2.0 for authorization. Unlike GitHub (which issues long-lived tokens), Google issues **short-lived access tokens** (~1 hour) paired with **refresh tokens** for obtaining new access tokens without re-prompting the user.

## Flow

1. **Redirect** — send user to Google's authorization endpoint with required parameters
2. **Consent** — user grants permissions on Google's consent screen
3. **Callback** — Google redirects back with a `code` query parameter
4. **Exchange** — POST the code to Google's token endpoint to get access + refresh tokens
5. **API calls** — use the access token for Google Calendar API requests
6. **Refresh** — when the access token expires, use the refresh token to get a new one

## Authorization URL

```
https://accounts.google.com/o/oauth2/v2/auth
```

### Query Parameters

| Parameter                 | Required | Description                                                        |
|---------------------------|----------|--------------------------------------------------------------------|
| `client_id`               | yes      | OAuth client ID from Google Cloud Console                          |
| `redirect_uri`            | yes      | Must exactly match an authorized URI in the console                |
| `response_type`           | yes      | Must be `code`                                                     |
| `scope`                   | yes      | Space-delimited list of requested permissions                      |
| `access_type`             | yes      | Must be `offline` to receive refresh tokens                        |
| `state`                   | yes      | Random CSRF token — must be validated on callback                  |
| `prompt`                  | no       | `consent` to force re-consent, `select_account` for account picker |
| `include_granted_scopes`  | no       | `true` for incremental authorization                               |
| `login_hint`              | no       | Email to prefill on the consent screen                             |

Example:

```
https://accounts.google.com/o/oauth2/v2/auth?client_id=CLIENT_ID&redirect_uri=http://localhost:5173/google-calendar/callback&response_type=code&scope=https://www.googleapis.com/auth/calendar.readonly&access_type=offline&state=random_token
```

## Token Exchange

```
POST https://oauth2.googleapis.com/token
Content-Type: application/x-www-form-urlencoded
```

### Request Parameters

| Parameter       | Required | Description                              |
|-----------------|----------|------------------------------------------|
| `code`          | yes      | Authorization code from callback         |
| `client_id`     | yes      | OAuth client ID                          |
| `client_secret` | yes      | OAuth client secret                      |
| `redirect_uri`  | yes      | Must match the original authorization    |
| `grant_type`    | yes      | Must be `authorization_code`             |

### Response

```json
{
  "access_token": "ya29.a0AfH6SM...",
  "expires_in": 3599,
  "refresh_token": "1//0eXy...",
  "token_type": "Bearer",
  "scope": "https://www.googleapis.com/auth/calendar.readonly"
}
```

**Important:** The `refresh_token` is only returned on the **first** authorization. Subsequent authorizations return only the access token unless `prompt=consent` is used to force re-consent.

## Refreshing Access Tokens

```
POST https://oauth2.googleapis.com/token
Content-Type: application/x-www-form-urlencoded
```

### Request Parameters

| Parameter       | Required | Description           |
|-----------------|----------|-----------------------|
| `grant_type`    | yes      | Must be `refresh_token` |
| `client_id`     | yes      | OAuth client ID       |
| `client_secret` | yes      | OAuth client secret   |
| `refresh_token` | yes      | The stored refresh token |

### Response

```json
{
  "access_token": "ya29.a0AfH6SM...",
  "expires_in": 3599,
  "token_type": "Bearer",
  "scope": "https://www.googleapis.com/auth/calendar.readonly"
}
```

## Token Revocation

```
POST https://oauth2.googleapis.com/revoke
Content-Type: application/x-www-form-urlencoded

token=ACCESS_OR_REFRESH_TOKEN
```

Revoking a refresh token also revokes the associated access token.

## Recommended Scopes

| Scope                                                      | Reason                               |
|------------------------------------------------------------|--------------------------------------|
| `https://www.googleapis.com/auth/calendar.readonly`        | Read calendar events and metadata    |
| `https://www.googleapis.com/auth/calendar.events.readonly` | Read events only (narrower)          |

For SynkHub, `calendar.readonly` is sufficient — we only need to read events, not create or modify them.

## Key Differences from GitHub OAuth

| Aspect          | GitHub                          | Google                                      |
|-----------------|---------------------------------|---------------------------------------------|
| Token lifetime  | Long-lived (no expiry)          | Access token ~1 hour, refresh token long-lived |
| Refresh tokens  | Not used                        | Required for ongoing access                 |
| Token exchange  | Simple POST                     | POST with `grant_type` parameter            |
| Scopes format   | Space-separated short names     | Full URL-based scope identifiers            |
| State parameter | Recommended                     | Required                                    |
| Re-consent      | Not needed                      | Needed to get new refresh token             |

## Security

- **Validate `state` param** — store a random token in cache before redirect, verify on callback
- **Store tokens encrypted** — use Rails `encrypts` for both access and refresh tokens
- **Set `access_type=offline`** — required to receive refresh tokens
- **Refresh proactively** — refresh the access token before it expires to avoid failed API calls
- **Use HTTPS** in production redirect URIs
