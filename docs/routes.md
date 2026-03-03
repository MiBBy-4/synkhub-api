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
