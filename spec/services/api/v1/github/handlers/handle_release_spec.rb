# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandleRelease do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:release_name) { "v1.0" }
    let(:release_url) { "https://github.com/#{repo_full_name}/releases/tag/v1.0" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "release",
             action: "published",
             payload: {
               "action" => "published",
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
               "sender" => { "login" => actor },
               "release" => { "name" => release_name, "tag_name" => "v1.0", "html_url" => release_url },
             })
    end
    let(:user) { create(:user) }
    let(:result) { described_class.call(event: event) }

    before do
      create(:github_repo_subscription, user: user, github_repo_id: repo_github_id)
    end

    it "creates a notification with correct title and url" do
      expect(result).to be_success
      notification = GithubNotification.last
      expect(notification.title).to eq("#{actor} published release #{release_name} in #{repo_full_name}")
      expect(notification.url).to eq(release_url)
    end
  end
end
