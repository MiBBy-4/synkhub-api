# GitHub Integration — Setup Guide

Step-by-step instructions to get GitHub OAuth and Webhooks working with SynkHub.

---

## Step 1: Create a GitHub OAuth App

1. Go to **GitHub** → **Settings** → **Developer settings** → **OAuth Apps** → **New OAuth App**
2. Fill in the form:

| Field | Value |
|-------|-------|
| **Application name** | `SynkHub` (or anything you like) |
| **Homepage URL** | `http://localhost:5173` |
| **Authorization callback URL** | `http://localhost:5173/github/callback` |
| **Enable Device Flow** | Leave **unchecked** (we use the web flow) |

3. Click **Register application**
4. Copy the **Client ID** — this is your `GITHUB_CLIENT_ID`
5. Click **Generate a new client secret** — copy it, this is your `GITHUB_CLIENT_SECRET`

---

## Step 2: Generate a Webhook Secret

Run this in your terminal:

```bash
openssl rand -hex 32
```

Copy the output — this is your `GITHUB_WEBHOOK_SECRET`. You'll paste the same value into GitHub when creating a webhook later.

---

## Step 3: Set Environment Variables

Add to your `.env` file (copy from `.env.example` if you haven't):

```env
GITHUB_CLIENT_ID=<Client ID from Step 1>
GITHUB_CLIENT_SECRET=<Client Secret from Step 1>
GITHUB_REDIRECT_URI=http://localhost:5173/github/callback
GITHUB_WEBHOOK_SECRET=<output from Step 2>
```

**Notes:**
- `GITHUB_REDIRECT_URI` must match the "Authorization callback URL" from Step 1 exactly
- `GITHUB_WEBHOOK_SECRET` is a value you create — it's not from GitHub

---

## Step 4: Run Migrations

```bash
docker exec synkhub-api-development-rails bundle exec rails db:migrate
```

This adds GitHub fields to the `users` table and creates the `github_webhook_events` table.

---

## How the OAuth Flow Works

```
┌──────────┐     GET /api/v1/github/auth      ┌──────────┐
│          │ ──────────────────────────────────►│          │
│          │     { url: "https://github..." }   │          │
│          │ ◄──────────────────────────────────│          │
│          │                                    │          │
│ Frontend │     Browser redirect to GitHub     │ Backend  │
│ :5173    │ ──► GitHub ──► authorize ──►        │ :3000    │
│          │     redirect to localhost:5173      │          │
│          │     /github/callback?code=X&state=Y│          │
│          │                                    │          │
│          │     POST /api/v1/github/callback   │          │
│          │     { code: X, state: Y }          │          │
│          │ ──────────────────────────────────►│          │
│          │                                    │ Exchanges │
│          │     { user: { github_username,     │ code for │
│          │       github_connected: true } }   │ token    │
│          │ ◄──────────────────────────────────│          │
└──────────┘                                    └──────────┘
```

1. Frontend calls `GET /api/v1/github/auth` (with JWT) — gets a GitHub authorization URL
2. Frontend redirects the user's browser to that URL
3. User authorizes on GitHub
4. GitHub redirects browser back to `localhost:5173/github/callback?code=...&state=...`
5. Frontend sends `POST /api/v1/github/callback` with `code` and `state` (with JWT)
6. Backend verifies `state` (CSRF), exchanges `code` for access token, fetches GitHub profile
7. User record is updated with `github_uid`, `github_username`, `github_access_token`

**No ngrok needed** — this is all browser redirects, not server-to-server.

---

## How Webhooks Work

```
┌──────────┐                                    ┌──────────┐
│          │    POST /api/v1/webhooks/github     │          │
│  GitHub  │ ──────────────────────────────────►│  Backend │
│          │    Headers: X-GitHub-Event,         │          │
│          │    X-GitHub-Delivery,               │          │
│          │    X-Hub-Signature-256              │  1. Verify signature
│          │                                    │  2. Store event (pending)
│          │    200 OK                           │  3. Enqueue Sidekiq job
│          │ ◄──────────────────────────────────│          │
└──────────┘                                    └──────────┘
                                                      │
                                                      ▼
                                                ┌──────────┐
                                                │ Sidekiq  │
                                                │          │
                                                │ Process  │
                                                │ event    │
                                                │ async    │
                                                └──────────┘
```

1. Someone pushes code, opens a PR, etc. on a GitHub repo with a webhook configured
2. GitHub sends a POST to our endpoint with the event payload
3. Backend verifies the HMAC signature (proves it's from GitHub)
4. Creates a `GithubWebhookEvent` record (status: `pending`)
5. Enqueues `ProcessGithubWebhookEventWorker` and returns `200 OK` immediately
6. Sidekiq processes the event asynchronously

**Ngrok IS needed** for this in local dev — GitHub must reach your server.

---

## Setting Up Webhooks (When Ready)

### Option A: Test Locally with curl (No ngrok needed)

```bash
SECRET="<your GITHUB_WEBHOOK_SECRET>"
BODY='{"ref":"refs/heads/main"}'
SIG="sha256=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')"

curl -X POST http://localhost:3000/api/v1/webhooks/github \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: $SIG" \
  -H "X-GitHub-Event: push" \
  -H "X-GitHub-Delivery: $(uuidgen)" \
  -d "$BODY"
```

### Option B: Real Webhooks with ngrok

1. Start ngrok:
   ```bash
   ngrok http 3000
   ```
2. Copy the HTTPS URL (e.g., `https://abc123.ngrok-free.app`)
3. On your GitHub repo: **Settings** → **Webhooks** → **Add webhook**:

   | Field | Value |
   |-------|-------|
   | **Payload URL** | `https://abc123.ngrok-free.app/api/v1/webhooks/github` |
   | **Content type** | `application/json` |
   | **Secret** | Same value as your `GITHUB_WEBHOOK_SECRET` env var |
   | **Events** | Choose specific events or "Send me everything" |

4. GitHub will send a `ping` event to verify — you should see a `200 OK`

**Note:** Free ngrok URLs change on restart. You'll need to update the webhook URL each time. This is fine for development — production will have a stable URL.

---

## Disconnecting GitHub

Call `DELETE /api/v1/github/disconnect` (with JWT) to remove the GitHub connection. This clears all `github_*` fields on the user.

---

## Environment Variables Summary

| Variable | Source | Purpose |
|----------|--------|---------|
| `GITHUB_CLIENT_ID` | GitHub OAuth App settings page | Identifies your app during OAuth |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth App settings page | Exchanges auth codes for tokens |
| `GITHUB_REDIRECT_URI` | You define it (must match OAuth App) | Where GitHub redirects after authorization |
| `GITHUB_WEBHOOK_SECRET` | You generate it (`openssl rand -hex 32`) | Verifies webhook payloads are from GitHub |
