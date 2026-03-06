# Google Calendar Integration — Setup Guide

## Prerequisites

- A Google Cloud project
- Google Calendar API enabled
- OAuth 2.0 credentials (Web application type)

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Note the project ID

## Step 2: Enable Google Calendar API

1. Go to **APIs & Services > Library**
2. Search for "Google Calendar API"
3. Click **Enable**

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services > OAuth consent screen**
2. Select **External** user type (for testing)
3. Fill in the required fields:
   - App name: `SynkHub`
   - User support email: your email
   - Developer contact email: your email
4. Add scopes:
   - `https://www.googleapis.com/auth/calendar.readonly`
5. Add test users (your Google account email) — required while in "Testing" status
6. Save

**Note:** While the app is in "Testing" status, only listed test users can authorize. To allow any Google user, you must submit for verification.

## Step 4: Create OAuth 2.0 Credentials

1. Go to **APIs & Services > Credentials**
2. Click **Create Credentials > OAuth client ID**
3. Application type: **Web application**
4. Name: `SynkHub Development`
5. Authorized redirect URIs:
   - `http://localhost:5173/google-calendar/callback` (frontend dev server)
6. Click **Create**
7. Copy the **Client ID** and **Client Secret**

## Step 5: Configure Environment Variables

Add to your Rails environment (`.env` or Docker Compose):

```bash
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
GOOGLE_REDIRECT_URI=http://localhost:5173/google-calendar/callback
```

## Step 6: Verify the Integration

1. Start the application
2. Log in to SynkHub
3. Go to Settings and click "Connect Google Calendar"
4. You should be redirected to Google's consent screen
5. Authorize the app
6. You should be redirected back to SynkHub with your calendar connected

## Environment Variables Reference

| Variable                | Description                              | Example                                          |
|-------------------------|------------------------------------------|--------------------------------------------------|
| `GOOGLE_CLIENT_ID`     | OAuth client ID from Google Cloud Console | `123456789-abc.apps.googleusercontent.com`       |
| `GOOGLE_CLIENT_SECRET` | OAuth client secret                       | `GOCSPX-abc123...`                               |
| `GOOGLE_REDIRECT_URI`  | Callback URL (must match console config)  | `http://localhost:5173/google-calendar/callback`  |

## Scopes Used

| Scope                                                      | Purpose                            |
|------------------------------------------------------------|------------------------------------|
| `https://www.googleapis.com/auth/calendar.readonly`        | Read calendar list and events      |

## Troubleshooting

### "Access blocked: App is not verified"
Your app is in "Testing" status. Add your Google account as a test user in the OAuth consent screen settings.

### "redirect_uri_mismatch"
The redirect URI in your request doesn't match any authorized URI in the Google Cloud Console. Ensure they match exactly (including protocol, host, port, and path).

### "invalid_grant" on token exchange
The authorization code has expired (codes are single-use and expire in ~10 minutes) or has already been used. Restart the OAuth flow.

### Refresh token not returned
Google only returns the refresh token on the **first** authorization. To get a new one, either:
- Revoke the app's access in your Google Account settings, then re-authorize
- Use `prompt=consent` in the authorization URL to force re-consent
