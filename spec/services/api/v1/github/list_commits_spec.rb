# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::ListCommits do
  describe ".call" do
    let(:result) { described_class.call(user: user) }
    let(:user) { create(:user) }
    let(:repo_id) { Faker::Number.number(digits: 6) }
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }

    context "with no subscriptions" do
      it "returns a paginated result with empty items" do
        expect(result).to be_success
        expect(result.value.items).to eq([])
        expect(result.value.total).to eq(0)
      end
    end

    context "with subscriptions and push events" do
      let(:commit_sha) { SecureRandom.hex(20) }
      let(:commit_message) { Faker::Lorem.sentence }
      let(:author_name) { Faker::Name.name }
      let(:author_login) { Faker::Internet.username }
      let(:commit_url) { Faker::Internet.url }
      let(:timestamp) { Time.current.iso8601 }

      before do
        create(:github_repo_subscription, user: user, github_repo_id: repo_id, repo_full_name: repo_full_name)
        create(:github_webhook_event,
               event_type: "push",
               status: GithubWebhookEvent::PROCESSED_STATUS,
               payload: {
                 "repository" => { "id" => repo_id, "full_name" => repo_full_name },
                 "ref" => "refs/heads/main",
                 "pusher" => { "name" => author_login },
                 "commits" => [
                   {
                     "id" => commit_sha,
                     "message" => commit_message,
                     "author" => { "name" => author_name, "username" => author_login },
                     "url" => commit_url,
                     "timestamp" => timestamp,
                   },
                 ],
               })
      end

      it "returns commits from subscribed repos" do
        expect(result).to be_success
        expect(result.value.items.length).to eq(1)
        expect(result.value.items.first.sha).to eq(commit_sha)
        expect(result.value.items.first.message).to eq(commit_message)
        expect(result.value.items.first.repo_full_name).to eq(repo_full_name)
        expect(result.value.items.first.branch).to eq("main")
        expect(result.value.total).to eq(1)
      end
    end

    context "with push events for unsubscribed repos" do
      before do
        create(:github_webhook_event,
               event_type: "push",
               status: GithubWebhookEvent::PROCESSED_STATUS,
               payload: {
                 "repository" => { "id" => repo_id, "full_name" => repo_full_name },
                 "ref" => "refs/heads/main",
                 "pusher" => { "name" => "someone" },
                 "commits" => [{ "id" => SecureRandom.hex(20), "message" => "test", "author" => { "name" => "a", "username" => "b" }, "url" => "http://x", "timestamp" => Time.current.iso8601 }],
               })
      end

      it "returns a paginated result with empty items" do
        expect(result).to be_success
        expect(result.value.items).to eq([])
        expect(result.value.total).to eq(0)
      end
    end

    context "with page and limit" do
      let(:result) { described_class.call(user: user, page: 2, limit: 1) }

      before do
        create(:github_repo_subscription, user: user, github_repo_id: repo_id, repo_full_name: repo_full_name)
        create(:github_webhook_event,
               event_type: "push",
               status: GithubWebhookEvent::PROCESSED_STATUS,
               payload: {
                 "repository" => { "id" => repo_id, "full_name" => repo_full_name },
                 "ref" => "refs/heads/main",
                 "pusher" => { "name" => "dev" },
                 "commits" => [
                   { "id" => SecureRandom.hex(20), "message" => "first", "author" => { "name" => "a", "username" => "b" }, "url" => "http://x", "timestamp" => Time.current.iso8601 },
                   { "id" => SecureRandom.hex(20), "message" => "second", "author" => { "name" => "a", "username" => "b" }, "url" => "http://y", "timestamp" => 1.minute.ago.iso8601 },
                 ],
               })
      end

      it "returns the second page" do
        expect(result).to be_success
        expect(result.value.items.length).to eq(1)
        expect(result.value.page).to eq(2)
        expect(result.value.limit).to eq(1)
        expect(result.value.total).to eq(2)
      end
    end
  end
end
