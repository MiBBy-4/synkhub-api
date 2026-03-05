# frozen_string_literal: true

FactoryBot.define do
  factory :user_preference do
    user
    notification_event_types { GithubWebhookEvent::SUPPORTED_EVENTS }
    email_digest_enabled { false }
    email_digest_frequency { "weekly" }
  end
end
