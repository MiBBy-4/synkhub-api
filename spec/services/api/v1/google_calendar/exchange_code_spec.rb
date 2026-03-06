# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::GoogleCalendar::ExchangeCode do
  describe ".call" do
    let(:result) { described_class.call(user: user, code: code, state: state) }
    let(:user) { create(:user) }
    let(:code) { SecureRandom.hex(16) }
    let(:state) { SecureRandom.hex(32) }
    let(:access_token) { "ya29.#{SecureRandom.hex(16)}" }
    let(:refresh_token) { "1//#{SecureRandom.hex(16)}" }
    let(:google_uid) { Faker::Number.number(digits: 21).to_s }
    let(:google_email) { Faker::Internet.email }

    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_cache)
      Rails.cache.write("google_oauth_state:#{user.id}", state, expires_in: 10.minutes)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return("test_google_client_id")
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_SECRET").and_return("test_google_secret")
      allow(ENV).to receive(:fetch).with("GOOGLE_REDIRECT_URI").and_return("http://localhost:5173/google-calendar/callback")

      token_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/token") do
          [200, { "Content-Type" => "application/json" }, {
            "access_token" => access_token,
            "refresh_token" => refresh_token,
            "expires_in" => 3599,
            "token_type" => "Bearer",
            "scope" => "https://www.googleapis.com/auth/calendar.readonly",
          }]
        end
      end

      userinfo_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/oauth2/v3/userinfo") do
          [200, { "Content-Type" => "application/json" }, {
            "sub" => google_uid,
            "email" => google_email,
          }]
        end
      end

      allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
        url = args.first[:url] || args.first
        if url.to_s.include?("oauth2.googleapis.com")
          method.call(*args) do |f|
            block&.call(f)
            f.adapter :test, token_stubs
          end
        else
          method.call(*args) do |f|
            block&.call(f)
            f.adapter :test, userinfo_stubs
          end
        end
      end
    end

    context "with valid state and code" do
      before do
        result
        user.reload
      end

      it "updates the user with Google credentials and returns success" do
        expect(result).to be_success
        expect(result.value).to eq(user)
        expect(user.google_uid).to eq(google_uid)
        expect(user.google_email).to eq(google_email)
        expect(user.google_access_token).to eq(access_token)
        expect(user.google_refresh_token).to eq(refresh_token)
        expect(user.google_token_expires_at).to be_present
        expect(user.google_token_scope).to eq("https://www.googleapis.com/auth/calendar.readonly")
      end
    end

    context "with invalid state" do
      let(:state) { "invalid_state" }

      before { Rails.cache.delete("google_oauth_state:#{user.id}") }

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Invalid state parameter")
      end
    end

    context "when token exchange fails" do
      before do
        failed_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/token") do
            [200, { "Content-Type" => "application/json" }, { "error" => "invalid_grant" }]
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

    context "when no refresh token is returned" do
      before do
        token_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/token") do
            [200, { "Content-Type" => "application/json" }, {
              "access_token" => access_token,
              "expires_in" => 3599,
              "token_type" => "Bearer",
              "scope" => "https://www.googleapis.com/auth/calendar.readonly",
            }]
          end
        end

        allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
          method.call(*args) do |f|
            block&.call(f)
            f.adapter :test, token_stubs
          end
        end
      end

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("No refresh token received")
      end
    end

    context "when fetching user info fails" do
      before do
        token_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/token") do
            [200, { "Content-Type" => "application/json" }, {
              "access_token" => access_token,
              "refresh_token" => refresh_token,
              "expires_in" => 3599,
              "token_type" => "Bearer",
              "scope" => "https://www.googleapis.com/auth/calendar.readonly",
            }]
          end
        end

        userinfo_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/oauth2/v3/userinfo") do
            [401, { "Content-Type" => "application/json" }, { "error" => "invalid_token" }]
          end
        end

        allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
          url = args.first[:url] || args.first
          if url.to_s.include?("oauth2.googleapis.com")
            method.call(*args) do |f|
              block&.call(f)
              f.adapter :test, token_stubs
            end
          else
            method.call(*args) do |f|
              block&.call(f)
              f.adapter :test, userinfo_stubs
            end
          end
        end
      end

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Failed to fetch Google user info")
      end
    end
  end
end
