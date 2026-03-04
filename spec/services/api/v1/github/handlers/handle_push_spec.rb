# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandlePush do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:branch) { "main" }
    let(:commits) { [{ "id" => SecureRandom.hex(20) }, { "id" => SecureRandom.hex(20) }] }
    let(:compare_url) { "https://github.com/#{repo_full_name}/compare/abc...def" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "push",
             payload: {
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
               "sender" => { "login" => actor },
               "ref" => "refs/heads/#{branch}",
               "commits" => commits,
               "compare" => compare_url,
             })
    end
    let(:result) { described_class.call(event: event) }

    context "with subscribed users" do
      let(:user) { create(:user) }

      before do
        create(:github_repo_subscription, user: user, github_repo_id: repo_github_id)
      end

      it "creates a notification with correct title and url" do
        expect(result).to be_success
        notification = GithubNotification.last
        expect(notification.title).to eq("#{actor} pushed 2 commits to #{repo_full_name}:#{branch}")
        expect(notification.url).to eq(compare_url)
        expect(notification.user).to eq(user)
      end
    end

    context "with no subscribers" do
      it "returns success with nil" do
        expect(result).to be_success
        expect(result.value).to be_nil
      end
    end
  end
end
