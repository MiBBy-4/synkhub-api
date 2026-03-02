FROM ruby:3.4.3-alpine AS base-synkhub-api-image

RUN apk add --no-cache --update \
    bash \
    build-base \
    git \
    gcompat \
    tzdata \
    postgresql-dev \
    postgresql-client \
    yaml-dev

WORKDIR /app

FROM base-synkhub-api-image AS synkhub-api-development-image

COPY Gemfile* .

RUN bundle config set without 'production' \
    && MAKE="make --jobs 8" bundle install --retry 5

FROM base-synkhub-api-image AS synkhub-api-production-image

COPY Gemfile* .

RUN bundle config deployment true \
    && bundle config set without 'development test' \
    && MAKE="make --jobs 8" bundle install --retry 5

COPY . .
