# GitHub Webhooks Overview

> For step-by-step setup instructions, see [setup-guide.md](setup-guide.md).

## What Are Webhooks?

Webhooks are HTTP POST callbacks that GitHub sends to your server when events occur in a repository or organization. Instead of polling the API, you receive real-time notifications.

## How They Work

1. Configure a webhook on a GitHub repo or org (URL, secret, events)
2. When a subscribed event occurs, GitHub sends a POST request to your URL
3. The payload contains event details as JSON
4. Your server processes the event and responds with 2XX

## Setup

### Via GitHub UI

1. Go to repo **Settings** > **Webhooks** > **Add webhook**
2. Set **Payload URL** to your endpoint (e.g., `https://api.synkhub.com/api/v1/webhooks/github`)
3. Set **Content type** to `application/json`
4. Set **Secret** — a shared secret for signature verification
5. Choose events to subscribe to (or select "Send me everything")

### Via API

```
POST /repos/{owner}/{repo}/hooks
Authorization: Bearer <token>

{
  "config": {
    "url": "https://api.synkhub.com/api/v1/webhooks/github",
    "content_type": "json",
    "secret": "your_webhook_secret"
  },
  "events": ["push", "pull_request", "issues"],
  "active": true
}
```

## Ping Event

When you create a webhook, GitHub sends a `ping` event to verify the endpoint is reachable. The payload includes:

```json
{
  "zen": "Keep it logically awesome.",
  "hook_id": 12345,
  "hook": { ... }
}
```

Your server should respond with `200 OK`.

## Request Headers

| Header                  | Description                                |
|-------------------------|--------------------------------------------|
| `X-GitHub-Event`        | Event type (e.g., `push`, `pull_request`)  |
| `X-GitHub-Delivery`     | Unique UUID for this delivery              |
| `X-Hub-Signature-256`   | HMAC SHA-256 signature of the payload      |
| `Content-Type`          | `application/json`                         |
| `User-Agent`            | `GitHub-Hookshot/<id>`                     |

## Response Requirements

- Respond with **2XX status** within **10 seconds**
- If the endpoint fails, GitHub retries with exponential backoff
- After repeated failures, the webhook is disabled
