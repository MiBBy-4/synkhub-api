# frozen_string_literal: true

FactoryBot.define do
  factory :github_notification do
    user
    github_webhook_event
    event_type { GithubWebhookEvent::SUPPORTED_EVENTS.sample }
    action { "opened" }
    title { Faker::Lorem.sentence }
    url { Faker::Internet.url }
    repo_full_name { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    actor_login { Faker::Internet.username }
    read { false }
  end
end
