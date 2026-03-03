#!/bin/sh
set -e

# Remove stale PID file only if it exists
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# Check if the database already exists; if not, create, migrate, and seed
if ! psql "$DATABASE_URL" -lqt | cut -d \| -f 1 | grep -qw synkhub_api_development; then
  bundle exec rails db:create
  bundle exec rails db:migrate
  bundle exec rails db:seed
else
  bundle exec rails db:migrate
fi

exec "$@"
