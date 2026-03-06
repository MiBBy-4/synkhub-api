# Google Calendar Push Notifications

> Reference: [Push Notifications Guide](https://developers.google.com/workspace/calendar/api/guides/push)

## Overview

Google Calendar supports push notifications via "watch" channels. When events change on a watched calendar, Google sends an HTTPS POST to your webhook URL. Unlike GitHub webhooks (which include the full payload), Google notifications are **signals only** — they tell you something changed, but you must call the API to see what changed.

For SynkHub's initial implementation, **periodic polling with incremental sync** (via `syncToken`) is simpler and sufficient. Push notifications can be added later as an optimization.

## Setting Up a Watch Channel

```
POST https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events/watch
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "id": "unique-channel-id",
  "type": "web_hook",
  "address": "https://your-domain.com/api/v1/webhooks/google_calendar",
  "token": "optional-verification-token",
  "expiration": 1426325213000
}
```

### Request Fields

| Field        | Required | Description                                         |
|--------------|----------|-----------------------------------------------------|
| `id`         | yes      | Unique channel identifier (max 64 chars, UUID)      |
| `type`       | yes      | Must be `web_hook`                                  |
| `address`    | yes      | HTTPS webhook URL (must have valid SSL certificate) |
| `token`      | no       | Verification token sent back with notifications     |
| `expiration` | no       | Unix timestamp in milliseconds for channel expiry   |

### Response (HTTP 200)

```json
{
  "kind": "api#channel",
  "id": "channel-id",
  "resourceId": "resource-identifier",
  "resourceUri": "https://www.googleapis.com/calendar/v3/calendars/primary/events",
  "token": "your-token",
  "expiration": 1426325213000
}
```

## Notification Message Format

Google sends HTTPS POST requests to your webhook URL.

### Headers (Always Present)

| Header                     | Description                                        |
|----------------------------|----------------------------------------------------|
| `X-Goog-Channel-ID`       | Your channel identifier                            |
| `X-Goog-Message-Number`   | Integer incrementing per message (1 for sync)      |
| `X-Goog-Resource-ID`      | Opaque identifier for the watched resource         |
| `X-Goog-Resource-State`   | `sync` (initial), `exists` (changed), `not_exists` |
| `X-Goog-Resource-URI`     | API URI for the watched resource                   |

### Optional Headers

| Header                       | Description                     |
|------------------------------|---------------------------------|
| `X-Goog-Channel-Expiration`  | Human-readable expiration date  |
| `X-Goog-Channel-Token`       | Your verification token         |

### Message Body

**Notifications have no body.** You must call the Calendar API (using `syncToken` for efficiency) to retrieve the actual changes.

### Sync Message

When a watch channel is first created, Google sends an initial `sync` message:

```
X-Goog-Resource-State: sync
X-Goog-Message-Number: 1
```

Respond with `200 OK` to confirm the channel is working.

## Channel Expiration and Renewal

- Channels expire based on the lesser of your requested expiration and Google's internal limit
- **No automatic renewal** — you must create a new watch channel before the old one expires
- Overlapping channels during renewal are normal and expected
- Each new channel must have a unique `id`

## Stopping Notifications

```
POST https://www.googleapis.com/calendar/v3/channels/stop
Content-Type: application/json

{
  "id": "channel-id",
  "resourceId": "resource-id"
}
```

Only the user/client that created the channel can stop it.

## SSL Requirements

The webhook URL must:
- Use HTTPS (not HTTP)
- Have a valid SSL certificate (not self-signed)
- Certificate must match the hostname
- Certificate must not be expired or revoked

## Important Limitations

- **Separate watches per calendar** — each calendar needs its own watch channel
- **Not 100% reliable** — a small percentage of notifications may be dropped
- **No payload** — you must make API calls to see what changed
- **Channel lifetime** — limited by Google's internal maximum (typically days, not months)

## Recommended Approach for SynkHub

Given the limitations (no payload, requires HTTPS with valid SSL, channels expire), the recommended initial approach is:

1. **Periodic polling** via Sidekiq scheduled worker (every 5-15 minutes)
2. **Incremental sync** using `syncToken` to fetch only changes
3. **Push notifications** can be added later for near-real-time updates in production

This mirrors the pattern used for GitHub, where we already have a background worker for processing events.
