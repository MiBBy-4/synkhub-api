# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Github", type: :request do
  describe "GET /api/v1/github/auth" do
    let(:headers) { {} }
    let(:user) { create(:user) }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Api::V1::Github::GenerateAuthUrl).to receive(:call).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_ID").and_return("test_client_id")
      allow(ENV).to receive(:fetch).with("GITHUB_REDIRECT_URI").and_return("http://localhost:5173/github/callback")
      get "/api/v1/github/auth", headers: headers
    end

    context "with a valid token" do
      let(:headers) { auth_headers_for(user) }

      it "calls GenerateAuthUrl and returns :ok with url" do
        expect(Api::V1::Github::GenerateAuthUrl).to have_received(:call).with(user: user)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["url"]).to include("https://github.com/login/oauth/authorize")
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "POST /api/v1/github/callback" do
    let(:headers) { {} }
    let(:user) { create(:user) }
    let(:code) { SecureRandom.hex(16) }
    let(:state) { SecureRandom.hex(32) }
    let(:params) { { code: code, state: state } }
    let(:access_token) { "gho_#{SecureRandom.hex(16)}" }
    let(:github_user_id) { rand(100_000..999_999) }
    let(:github_username) { Faker::Internet.username }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Api::V1::Github::ExchangeCode).to receive(:call).and_call_original
      Rails.cache.write("github_oauth_state:#{user.id}", state, expires_in: 10.minutes)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_ID").and_return("test_client_id")
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_SECRET").and_return("test_secret")
      allow(ENV).to receive(:fetch).with("GITHUB_REDIRECT_URI").and_return("http://localhost:5173/github/callback")

      oauth_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/login/oauth/access_token") do
          [200, { "Content-Type" => "application/json" }, { "access_token" => access_token, "scope" => "repo" }]
        end
      end

      api_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/user") do
          [200, { "Content-Type" => "application/json" }, { "id" => github_user_id, "login" => github_username }]
        end
      end

      allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
        url = args.first[:url] || args.first
        if url.to_s.include?("api.github.com")
          method.call(*args) do |f|
            block&.call(f)
            f.adapter :test, api_stubs
          end
        else
          method.call(*args) do |f|
            block&.call(f)
            f.adapter :test, oauth_stubs
          end
        end
      end

      post "/api/v1/github/callback", params: params, headers: headers
    end

    context "with a valid token and params" do
      let(:headers) { auth_headers_for(user) }

      it "calls ExchangeCode and returns :ok with user" do
        expect(Api::V1::Github::ExchangeCode).to have_received(:call).with(
          user: user, code: code, state: state
        )
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["github_username"]).to eq(github_username)
        expect(response.parsed_body["data"]["github_connected"]).to be(true)
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "DELETE /api/v1/github/disconnect" do
    let(:headers) { {} }
    let(:github_uid) { Faker::Number.number(digits: 8).to_s }
    let(:github_username) { Faker::Internet.username }
    let(:github_access_token) { "gho_#{SecureRandom.hex(16)}" }
    let(:user) do
      create(:user,
             github_uid: github_uid,
             github_username: github_username,
             github_access_token: github_access_token,
             github_token_scope: "repo")
    end

    before do
      allow(Api::V1::Github::Disconnect).to receive(:call).and_call_original
      delete "/api/v1/github/disconnect", headers: headers
    end

    context "with a valid token" do
      let(:headers) { auth_headers_for(user) }

      it "calls Disconnect and returns :ok with user" do
        expect(Api::V1::Github::Disconnect).to have_received(:call).with(user: user)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["github_connected"]).to be(false)
        expect(response.parsed_body["data"]["github_username"]).to be_nil
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
