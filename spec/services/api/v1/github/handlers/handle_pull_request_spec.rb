# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandlePullRequest do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:pr_number) { rand(1..100) }
    let(:pr_title) { Faker::Lorem.sentence }
    let(:merged) { false }
    let(:action) { "opened" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "pull_request",
             action: action,
             payload: {
               "action" => action,
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
               "sender" => { "login" => actor },
               "pull_request" => {
                 "number" => pr_number,
                 "title" => pr_title,
                 "html_url" => "https://github.com/#{repo_full_name}/pull/#{pr_number}",
                 "merged" => merged,
               },
             })
    end
    let(:user) { create(:user) }
    let(:result) { described_class.call(event: event) }

    before do
      create(:github_repo_subscription, user: user, github_repo_id: repo_github_id)
    end

    context "when opened" do
      it "creates notification with 'opened' verb" do
        expect(result).to be_success
        expect(GithubNotification.last.title).to eq("#{actor} opened PR ##{pr_number}: #{pr_title} in #{repo_full_name}")
      end
    end

    context "when closed and merged" do
      let(:action) { "closed" }
      let(:merged) { true }

      it "creates notification with 'merged' verb" do
        expect(result).to be_success
        expect(GithubNotification.last.title).to eq("#{actor} merged PR ##{pr_number}: #{pr_title} in #{repo_full_name}")
      end
    end

    context "when closed without merge" do
      let(:action) { "closed" }

      it "creates notification with 'closed' verb" do
        expect(result).to be_success
        expect(GithubNotification.last.title).to eq("#{actor} closed PR ##{pr_number}: #{pr_title} in #{repo_full_name}")
      end
    end
  end
end
