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

### GET /api/v1/github/repositories

Lists GitHub repositories accessible to the authenticated user.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `200 OK`

```json
{
  "data": [
    {
      "id": 123456,
      "full_name": "org/repo",
      "name": "repo",
      "private": false,
      "owner_login": "org"
    }
  ],
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token
- `422 Unprocessable Entity` — GitHub account not connected

---

### GET /api/v1/github/subscriptions

Lists the authenticated user's repo subscriptions.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `200 OK`

```json
{
  "data": [
    {
      "id": 1,
      "github_repo_id": 123456,
      "repo_full_name": "org/repo",
      "created_at": "2026-03-04T12:00:00Z"
    }
  ],
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token

---

### POST /api/v1/github/subscriptions

Subscribe to a GitHub repository. Creates a webhook on GitHub for the repo.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Request body:**

| Field             | Type    | Required | Description             |
|-------------------|---------|----------|-------------------------|
| `github_repo_id`  | integer | yes      | GitHub's numeric repo ID |
| `repo_full_name`  | string  | yes      | e.g. `"org/repo"`       |

**Success response:** `200 OK`

```json
{
  "data": {
    "id": 1,
    "github_repo_id": 123456,
    "repo_full_name": "org/repo",
    "created_at": "2026-03-04T12:00:00Z"
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token
- `422 Unprocessable Entity` — already subscribed, GitHub not connected, or webhook creation failed

---

### DELETE /api/v1/github/subscriptions/:id

Unsubscribe from a repo. Deletes the webhook from GitHub.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `204 No Content`

**Error responses:**

- `401 Unauthorized` — missing or invalid token
- `422 Unprocessable Entity` — subscription not found

---

### GET /api/v1/github/notifications

Lists the authenticated user's notifications (newest first).

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `200 OK`

```json
{
  "data": [
    {
      "id": 1,
      "event_type": "push",
      "action": null,
      "title": "octocat pushed 3 commits to org/repo:main",
      "url": "https://github.com/org/repo/compare/abc...def",
      "repo_full_name": "org/repo",
      "actor_login": "octocat",
      "read": false,
      "created_at": "2026-03-04T12:00:00Z"
    }
  ],
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token

---

### PATCH /api/v1/github/notifications/:id/read

Marks a single notification as read.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `200 OK`

```json
{
  "data": {
    "id": 1,
    "event_type": "push",
    "action": null,
    "title": "octocat pushed 3 commits to org/repo:main",
    "url": "https://github.com/org/repo/compare/abc...def",
    "repo_full_name": "org/repo",
    "actor_login": "octocat",
    "read": true,
    "created_at": "2026-03-04T12:00:00Z"
  },
  "meta": {}
}
```

**Error responses:**

- `401 Unauthorized` — missing or invalid token
- `404 Not Found` — notification not found

---

### PATCH /api/v1/github/notifications/read_all

Marks all unread notifications as read.

**Headers:** `Authorization: Bearer <jwt_token>` (required)

**Success response:** `204 No Content`

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
