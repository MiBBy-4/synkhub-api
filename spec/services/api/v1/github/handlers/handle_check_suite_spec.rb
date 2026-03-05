# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandleCheckSuite do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:conclusion) { "success" }
    let(:repo_url) { "https://github.com/#{repo_full_name}" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "check_suite",
             action: "completed",
             payload: {
               "action" => "completed",
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id, "html_url" => repo_url },
               "sender" => { "login" => actor },
               "check_suite" => { "conclusion" => conclusion },
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
      expect(notification.title).to eq("Check suite completed (#{conclusion}) in #{repo_full_name}")
      expect(notification.url).to eq("#{repo_url}/actions")
    end
  end
end
