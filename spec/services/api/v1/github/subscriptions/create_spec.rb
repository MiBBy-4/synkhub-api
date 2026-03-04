# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Subscriptions::Create do
  describe ".call" do
    let(:user) { create(:user, github_uid: "12345", github_access_token: "gho_#{SecureRandom.hex(16)}", github_token_scope: "repo admin:repo_hook") }
    let(:github_repo_id) { rand(100_000..999_999) }
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:webhook_id) { rand(100_000..999_999) }
    let(:result) { described_class.call(user: user, github_repo_id: github_repo_id, repo_full_name: repo_full_name) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_WEBHOOK_URL").and_return("https://example.com/api/v1/webhooks/github")
      allow(ENV).to receive(:fetch).with("GITHUB_WEBHOOK_SECRET").and_return("test_secret")

      api_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/repos/#{repo_full_name}/hooks") do
          [201, { "Content-Type" => "application/json" }, { "id" => webhook_id }]
        end
      end

      allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
        method.call(*args) do |f|
          block&.call(f)
          f.adapter :test, api_stubs
        end
      end
    end

    context "with valid params" do
      it "creates a subscription and webhook" do
        expect(result).to be_success
        subscription = result.value
        expect(subscription).to be_a(GithubRepoSubscription)
        expect(subscription.github_repo_id).to eq(github_repo_id)
        expect(subscription.repo_full_name).to eq(repo_full_name)
        expect(subscription.webhook_github_id).to eq(webhook_id)
      end
    end

    context "when already subscribed" do
      before do
        create(:github_repo_subscription, user: user, github_repo_id: github_repo_id)
      end

      it "returns error" do
        expect(result).to be_error
        expect(result.error).to eq("Already subscribed")
      end
    end

    context "when GitHub account not connected" do
      let(:user) { create(:user) }

      it "returns error" do
        expect(result).to be_error
        expect(result.error).to eq("GitHub account not connected")
      end
    end

    context "when missing admin:repo_hook scope" do
      let(:user) { create(:user, github_uid: "12345", github_access_token: "gho_#{SecureRandom.hex(16)}", github_token_scope: "repo read:user") }

      it "returns error" do
        expect(result).to be_error
        expect(result.error).to eq("Missing required GitHub scope: admin:repo_hook. Please reconnect your GitHub account.")
      end
    end
  end
end
