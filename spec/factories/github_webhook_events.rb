# frozen_string_literal: true

FactoryBot.define do
  factory :github_webhook_event do
    event_type { GithubWebhookEvent::SUPPORTED_EVENTS.sample }
    action { "opened" }
    delivery_id { SecureRandom.uuid }
    payload { { "repository" => { "full_name" => "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" } } }
    status { GithubWebhookEvent::PENDING_STATUS }
  end
end
