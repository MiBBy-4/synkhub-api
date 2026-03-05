# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Github::Subscriptions", type: :request do
  let(:user) { create(:user, github_uid: "12345", github_access_token: "gho_#{SecureRandom.hex(16)}", github_token_scope: "repo admin:repo_hook") }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/github/subscriptions" do
    before do
      create(:github_repo_subscription, user: user)
      get "/api/v1/github/subscriptions", headers: headers
    end

    context "with a valid token" do
      it "returns subscriptions" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"].size).to eq(1)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "POST /api/v1/github/subscriptions" do
    let(:github_repo_id) { rand(100_000..999_999) }
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:webhook_id) { rand(100_000..999_999) }
    let(:params) { { github_repo_id: github_repo_id, repo_full_name: repo_full_name } }

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

      post "/api/v1/github/subscriptions", params: params, headers: headers
    end

    context "with valid params" do
      it "creates a subscription" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["repo_full_name"]).to eq(repo_full_name)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "DELETE /api/v1/github/subscriptions/:id" do
    let(:subscription) { create(:github_repo_subscription, user: user) }

    before do
      api_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.delete("/repos/#{subscription.repo_full_name}/hooks/#{subscription.webhook_github_id}") do
          [204, {}, nil]
        end
      end

      allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
        method.call(*args) do |f|
          block&.call(f)
          f.adapter :test, api_stubs
        end
      end

      delete "/api/v1/github/subscriptions/#{subscription.id}", headers: headers
    end

    context "with a valid token" do
      it "destroys the subscription" do
        expect(response).to have_http_status(:no_content)
        expect(GithubRepoSubscription.find_by(id: subscription.id)).to be_nil
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
