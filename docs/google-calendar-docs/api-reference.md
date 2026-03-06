# Google Calendar API Reference

> Reference: [Google Calendar API v3](https://developers.google.com/workspace/calendar/api/v3/reference)

## Base URL

```
https://www.googleapis.com/calendar/v3
```

All requests require an `Authorization: Bearer <access_token>` header.

---

## CalendarList: list

Lists all calendars the user has access to.

```
GET https://www.googleapis.com/calendar/v3/users/me/calendarList
```

### Query Parameters

| Parameter       | Type    | Default | Description                                                 |
|-----------------|---------|---------|-------------------------------------------------------------|
| `maxResults`    | integer | 100     | Max entries per page (max 250)                              |
| `minAccessRole` | string  |         | Filter by access: `freeBusyReader`, `reader`, `writer`, `owner` |
| `pageToken`     | string  |         | Pagination token                                            |
| `showDeleted`   | boolean | false   | Include deleted calendars                                   |
| `showHidden`    | boolean | false   | Include hidden calendars                                    |
| `syncToken`     | string  |         | Incremental sync token                                      |

### Response

```json
{
  "kind": "calendar#calendarList",
  "etag": "...",
  "nextPageToken": "...",
  "nextSyncToken": "...",
  "items": [
    {
      "kind": "calendar#calendarListEntry",
      "id": "primary",
      "summary": "My Calendar",
      "description": "Personal events",
      "timeZone": "America/New_York",
      "colorId": "1",
      "backgroundColor": "#ac725e",
      "foregroundColor": "#1d1d1d",
      "accessRole": "owner",
      "primary": true,
      "selected": true
    }
  ]
}
```

### Authorization Scopes

- `calendar.readonly`
- `calendar`
- `calendar.calendarlist`
- `calendar.calendarlist.readonly`

---

## Events: list

Lists events on a specified calendar.

```
GET https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events
```

Use `primary` as `calendarId` for the user's primary calendar.

### Query Parameters

| Parameter        | Type     | Default | Description                                             |
|------------------|----------|---------|---------------------------------------------------------|
| `timeMin`        | datetime |         | Lower bound for event end time (RFC3339)                |
| `timeMax`        | datetime |         | Upper bound for event start time (RFC3339)              |
| `singleEvents`   | boolean  | false   | Expand recurring events into instances                  |
| `orderBy`        | string   |         | `startTime` (requires singleEvents=true) or `updated`  |
| `maxResults`     | integer  | 250     | Max events per page (max 2500)                          |
| `pageToken`      | string   |         | Pagination token                                        |
| `q`              | string   |         | Free text search across event fields                    |
| `timeZone`       | string   |         | Timezone for response (default: calendar timezone)      |
| `syncToken`      | string   |         | Incremental sync — only changed events since last sync  |
| `updatedMin`     | datetime |         | Filter by last modification time (RFC3339)              |
| `showDeleted`    | boolean  | false   | Include cancelled events                                |
| `eventTypes`     | string   |         | Filter: `default`, `birthday`, `focusTime`, `outOfOffice`, `workingLocation` |

### Response

```json
{
  "kind": "calendar#events",
  "etag": "...",
  "summary": "Calendar Name",
  "updated": "2026-03-05T12:00:00.000Z",
  "timeZone": "America/New_York",
  "accessRole": "owner",
  "nextPageToken": "...",
  "nextSyncToken": "...",
  "defaultReminders": [
    { "method": "popup", "minutes": 10 }
  ],
  "items": [
    { "...event resource..." }
  ]
}
```

### Authorization Scopes

- `calendar.readonly`
- `calendar`
- `calendar.events.readonly`
- `calendar.events`

---

## Event Resource

Key fields of a Google Calendar event object:

### Core Fields

| Field           | Type     | Description                                    |
|-----------------|----------|------------------------------------------------|
| `id`            | string   | Opaque event identifier                        |
| `status`        | string   | `confirmed`, `tentative`, or `cancelled`       |
| `htmlLink`      | string   | URL to event in Google Calendar web UI         |
| `summary`       | string   | Event title                                    |
| `description`   | string   | Event description (may contain HTML)           |
| `location`      | string   | Geographic location (free-form text)           |
| `colorId`       | string   | Color reference ID                             |
| `eventType`     | string   | `default`, `birthday`, `focusTime`, `outOfOffice`, `workingLocation` |

### Temporal Fields

| Field                 | Type   | Description                                      |
|-----------------------|--------|--------------------------------------------------|
| `start.date`          | string | Start date for all-day events (yyyy-mm-dd)       |
| `start.dateTime`      | string | Start time for timed events (RFC3339)            |
| `start.timeZone`      | string | Timezone (IANA)                                  |
| `end.date`            | string | End date for all-day events                      |
| `end.dateTime`        | string | End time for timed events (RFC3339)              |
| `end.timeZone`        | string | Timezone (IANA)                                  |
| `created`             | string | Creation timestamp (RFC3339, read-only)          |
| `updated`             | string | Last modification timestamp (RFC3339, read-only) |

### Participants

| Field                         | Type   | Description                         |
|-------------------------------|--------|-------------------------------------|
| `creator.email`               | string | Creator's email                     |
| `creator.displayName`         | string | Creator's name                      |
| `creator.self`                | boolean| Whether the creator is the user     |
| `organizer.email`             | string | Organizer's email                   |
| `organizer.displayName`       | string | Organizer's name                    |
| `organizer.self`              | boolean| Whether the organizer is the user   |
| `attendees[].email`           | string | Attendee email                      |
| `attendees[].displayName`     | string | Attendee name                       |
| `attendees[].responseStatus`  | string | `needsAction`, `declined`, `tentative`, `accepted` |
| `attendees[].self`            | boolean| Whether the attendee is the user    |
| `attendees[].optional`        | boolean| Whether attendance is optional      |

### Recurrence

| Field              | Type     | Description                                  |
|--------------------|----------|----------------------------------------------|
| `recurrence[]`     | string[] | RRULE, EXRULE, RDATE, EXDATE (RFC5545)      |
| `recurringEventId` | string   | Parent recurring event ID (for instances)    |

### Other

| Field                 | Type    | Description                              |
|-----------------------|---------|------------------------------------------|
| `hangoutLink`         | string  | Google Hangout/Meet URL (read-only)      |
| `conferenceData`      | object  | Video conference details (Meet, Zoom)    |
| `reminders.useDefault`| boolean | Whether to use calendar default reminders|
| `reminders.overrides` | array   | Custom reminders (method + minutes)      |
| `visibility`          | string  | `default`, `public`, `private`, `confidential` |
| `transparency`        | string  | `opaque` (blocks time) or `transparent`  |
| `iCalUID`             | string  | RFC5545 unique identifier                |
| `sequence`            | integer | iCalendar sequence number                |

---

## Incremental Sync Strategy

For efficient syncing, use `syncToken`:

1. **Initial sync** — call `events.list` with `timeMin` and `singleEvents=true`. Save the `nextSyncToken` from the last page.
2. **Subsequent syncs** — call `events.list` with `syncToken`. Returns only changed/deleted events.
3. **Token invalidation** — if the API returns `410 Gone`, the sync token is stale. Perform a full sync again.

This avoids re-fetching all events on every sync and is the recommended approach for background polling.
