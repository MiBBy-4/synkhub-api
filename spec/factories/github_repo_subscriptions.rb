# frozen_string_literal: true

FactoryBot.define do
  factory :github_repo_subscription do
    user
    github_repo_id { rand(100_000..999_999) }
    repo_full_name { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    webhook_github_id { rand(100_000..999_999) }
  end
end
