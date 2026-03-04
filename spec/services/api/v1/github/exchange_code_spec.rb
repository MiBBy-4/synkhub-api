# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::ExchangeCode do
  describe ".call" do
    let(:result) { described_class.call(user: user, code: code, state: state) }
    let(:user) { create(:user) }
    let(:code) { SecureRandom.hex(16) }
    let(:state) { SecureRandom.hex(32) }
    let(:access_token) { "gho_#{SecureRandom.hex(16)}" }
    let(:github_user_id) { rand(100_000..999_999) }
    let(:github_username) { Faker::Internet.username }

    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_cache)
      Rails.cache.write("github_oauth_state:#{user.id}", state, expires_in: 10.minutes)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_ID").and_return("test_client_id")
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_SECRET").and_return("test_client_secret")
      allow(ENV).to receive(:fetch).with("GITHUB_REDIRECT_URI").and_return("http://localhost:5173/github/callback")

      oauth_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/login/oauth/access_token") do
          [200, { "Content-Type" => "application/json" }, { "access_token" => access_token, "scope" => "repo,read:user" }]
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
    end

    context "with valid state and code" do
      before do
        result
        user.reload
      end

      it "updates the user with GitHub credentials and returns success" do
        expect(result).to be_success
        expect(result.value).to eq(user)
        expect(user.github_uid).to eq(github_user_id.to_s)
        expect(user.github_username).to eq(github_username)
        expect(user.github_access_token).to eq(access_token)
        expect(user.github_token_scope).to eq("repo,read:user")
      end
    end

    context "with invalid state" do
      let(:state) { "invalid_state" }

      before { Rails.cache.delete("github_oauth_state:#{user.id}") }

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Invalid state parameter")
      end
    end

    context "when token exchange fails" do
      before do
        failed_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/login/oauth/access_token") do
            [200, { "Content-Type" => "application/json" }, { "error" => "bad_verification_code" }]
          end
        end

        allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
          method.call(*args) do |f|
            block&.call(f)
            f.adapter :test, failed_stubs
          end
        end
      end

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Failed to obtain access token")
      end
    end

    context "when fetching GitHub user fails" do
      before do
        oauth_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/login/oauth/access_token") do
            [200, { "Content-Type" => "application/json" }, { "access_token" => access_token, "scope" => "repo" }]
          end
        end

        api_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/user") do
            [200, { "Content-Type" => "application/json" }, { "message" => "Bad credentials" }]
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
      end

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Failed to fetch GitHub user")
      end
    end
  end
end
