# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandleIssueComment do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:issue_number) { rand(1..100) }
    let(:comment_url) { "https://github.com/#{repo_full_name}/issues/#{issue_number}#issuecomment-1" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "issue_comment",
             action: "created",
             payload: {
               "action" => "created",
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
               "sender" => { "login" => actor },
               "issue" => { "number" => issue_number },
               "comment" => { "html_url" => comment_url },
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
      expect(notification.title).to eq("#{actor} commented on issue ##{issue_number} in #{repo_full_name}")
      expect(notification.url).to eq(comment_url)
    end
  end
end
