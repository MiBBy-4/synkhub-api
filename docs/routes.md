# API Routes

Base URL: `/api/v1`

## Authentication

All authenticated endpoints require an `Authorization` header:

```
Authorization: Bearer <jwt_token>
```

Tokens expire after 24 hours. On expiry, the client must re-authenticate via `POST /api/v1/login`.

---

## Public Endpoints

### POST /api/v1/signup

Register a new user.

**Request body:**

| Field                   | Type   | Required | Constraints            |
|-------------------------|--------|----------|------------------------|
| `email`                 | string | yes      | Valid email, unique     |
| `password`              | string | yes      | Minimum 8 characters   |
| `password_confirmation` | string | yes      | Must match `password`   |

**Success response:** `201 Created`

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "token": "eyJhbGciOiJIUzI1NiJ9..."
  },
  "meta": {}
}
```

**Error responses:**

- `422 Unprocessable Entity` — validation failed (missing email, duplicate email, short password, mismatched confirmation)

```json
{
  "errors": ["Email has already been taken"]
}
```

---

### POST /api/v1/login

Authenticate an existing user.

**Request body:**

| Field      | Type   | Required |
|------------|--------|----------|
| `email`    | string | yes      |
| `password` | string | yes      |

**Success response:** `200 OK`

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "token": "eyJhbGciOiJIUzI1NiJ9..."
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — invalid credentials

```json
{
  "errors": ["Invalid email or password"]
}
```

```json
{
  "errors": ["User not found"]
}
```

---

## Authenticated Endpoints

### GET /api/v1/me

Returns the currently authenticated user.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `200 OK`

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com"
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token

```json
{
  "errors": ["You are unauthorized"]
}
```

---

### GET /api/v1/github/auth

Returns a GitHub OAuth authorization URL. The frontend should redirect the user to this URL.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `200 OK`

```json
{
  "data": {
    "url": "https://github.com/login/oauth/authorize?client_id=...&redirect_uri=...&scope=...&state=..."
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token

---

### POST /api/v1/github/callback

Exchanges a GitHub OAuth code for an access token and links the GitHub account to the user.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Request body:**

| Field   | Type   | Required | Description                         |
|---------|--------|----------|-------------------------------------|
| `code`  | string | yes      | Authorization code from GitHub      |
| `state` | string | yes      | CSRF state token (must match cache) |

**Success response:** `200 OK`

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "github_username": "octocat",
    "github_connected": true
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token
- `422 Unprocessable Entity` — invalid state, failed token exchange, or failed user fetch

---

### DELETE /api/v1/github/disconnect

Removes the GitHub connection from the user's account.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `200 OK`

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "github_username": null,
    "github_connected": false
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token

---

## Public Webhook Endpoints

### POST /api/v1/webhooks/github

Receives GitHub webhook events. No JWT required — authenticated via `X-Hub-Signature-256`.

**Headers:**

| Header                | Required | Description                              |
|-----------------------|----------|------------------------------------------|
| `X-Hub-Signature-256` | yes      | HMAC SHA-256 signature of the payload    |
| `X-GitHub-Event`      | yes      | Event type (e.g., `push`)               |
| `X-GitHub-Delivery`   | yes      | Unique delivery UUID                     |
| `Content-Type`        | yes      | `application/json`                       |

**Request body:** Raw JSON payload from GitHub (varies by event type)

**Success response:** `200 OK`

```json
{
  "data": {
    "id": 1,
    "status": "pending"
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — invalid or missing signature
- `422 Unprocessable Entity` — unsupported event type
