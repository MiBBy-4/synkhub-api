# SynkHub — Backend

SynkHub is a modular backend service designed to aggregate data from multiple external platforms and expose a unified API for a personal productivity dashboard. The backend is built with Ruby on Rails and focuses on clean architecture, extensibility, and reliable background processing.

---

## Overview

SynkHub integrates with several external services to collect and unify information relevant to a developer's daily workflow:

- **GitHub** — pull requests, review requests, repository activity.
- **Google Calendar** — upcoming events, daily schedule, meeting overview.
- **Shortcut** — tasks, stories, and project progress.

The backend is responsible for:

- authenticating users,
- managing integrations and tokens,
- synchronizing data from external APIs,
- processing webhook events,
- exposing a clean JSON API for the frontend.

This repository contains only the backend portion of the system. The frontend lives in a separate repository.

---

## Tech Stack

- **Ruby 3.4.3, Rails 8.0.2**
- **PostgreSQL** (primary database)
- **Sidekiq** (background jobs)
- **Redis** (Sidekiq queue)
- **RSpec** (testing)
- **RuboCop** (linting)
- **Docker Compose** (local development)
- **JSON API** (communication with frontend)

---

## Architecture

The backend follows a modular structure:

- `app/models/` — persistence and validations
- `app/services/` — integration logic, sync services, external API clients
- `app/controllers/api/` — versioned API endpoints
- `app/serializers/` — JSON serialization (Alba)
- `config/sidekiq.yml` — queue configuration
- `spec/` — RSpec test suite

Integrations with GitHub, Google Calendar, and Shortcut are implemented as separate service modules, each responsible for authentication, synchronization, and webhook handling.

---

## Running with Docker

### Start the environment

```bash
docker compose -f docker/development/compose.yml up --build
```

This will start:

- Rails API server (`synkhub-api-development-rails`)
- Sidekiq worker (`synkhub-api-development-sidekiq`)
- PostgreSQL (`synkhub-api-development-postgresql`)
- Redis (`synkhub-api-development-redis`)

### Run migrations

```bash
docker exec synkhub-api-development-rails bundle exec rails db:migrate
```

### Testing

```bash
docker exec synkhub-api-development-rails bundle exec rspec
```

### Linting

```bash
docker exec synkhub-api-development-rails bundle exec rubocop -A
```

---

## Documentation

- `CLAUDE.md` — rules and conventions for AI-assisted development
- `docs/routes.md` — API route documentation with request/response shapes
- `instruction.md` (parent directory) — conceptual architecture of the entire SynkHub system

---

## Future Development

- Additional integrations (Notion, Slack, Linear, Jira)
- More granular webhook processing
- Advanced caching and performance improvements
- User-configurable widget settings
