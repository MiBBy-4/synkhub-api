# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandleIssues do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:issue_number) { rand(1..100) }
    let(:issue_title) { Faker::Lorem.sentence }
    let(:issue_url) { "https://github.com/#{repo_full_name}/issues/#{issue_number}" }
    let(:action) { "opened" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "issues",
             action: action,
             payload: {
               "action" => action,
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
               "sender" => { "login" => actor },
               "issue" => { "number" => issue_number, "title" => issue_title, "html_url" => issue_url },
             })
    end
    let(:user) { create(:user) }
    let(:result) { described_class.call(event: event) }

    before do
      create(:github_repo_subscription, user: user, github_repo_id: repo_github_id)
    end

    context "when opened" do
      it "creates notification with 'opened' action" do
        expect(result).to be_success
        expect(GithubNotification.last.title).to eq("#{actor} opened issue ##{issue_number}: #{issue_title} in #{repo_full_name}")
      end
    end

    context "when closed" do
      let(:action) { "closed" }

      it "creates notification with 'closed' action" do
        expect(result).to be_success
        expect(GithubNotification.last.title).to eq("#{actor} closed issue ##{issue_number}: #{issue_title} in #{repo_full_name}")
      end
    end
  end
end
