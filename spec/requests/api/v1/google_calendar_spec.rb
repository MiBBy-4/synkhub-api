# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::GoogleCalendar", type: :request do
  describe "GET /api/v1/google_calendar/auth" do
    let(:headers) { {} }
    let(:user) { create(:user) }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Api::V1::GoogleCalendar::GenerateAuthUrl).to receive(:call).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return("test_google_client_id")
      allow(ENV).to receive(:fetch).with("GOOGLE_REDIRECT_URI").and_return("http://localhost:5173/google-calendar/callback")
      get "/api/v1/google_calendar/auth", headers: headers
    end

    context "with a valid token" do
      let(:headers) { auth_headers_for(user) }

      it "calls GenerateAuthUrl and returns :ok with url" do
        expect(Api::V1::GoogleCalendar::GenerateAuthUrl).to have_received(:call).with(user: user)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["url"]).to include("https://accounts.google.com/o/oauth2/v2/auth")
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "POST /api/v1/google_calendar/callback" do
    let(:headers) { {} }
    let(:user) { create(:user) }
    let(:code) { SecureRandom.hex(16) }
    let(:state) { SecureRandom.hex(32) }
    let(:params) { { code: code, state: state } }
    let(:access_token) { "ya29.#{SecureRandom.hex(16)}" }
    let(:refresh_token) { "1//#{SecureRandom.hex(16)}" }
    let(:google_uid) { Faker::Number.number(digits: 21).to_s }
    let(:google_email) { Faker::Internet.email }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Api::V1::GoogleCalendar::ExchangeCode).to receive(:call).and_call_original
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

      post "/api/v1/google_calendar/callback", params: params, headers: headers
    end

    context "with a valid token and params" do
      let(:headers) { auth_headers_for(user) }

      it "calls ExchangeCode and returns :ok with user" do
        expect(Api::V1::GoogleCalendar::ExchangeCode).to have_received(:call).with(
          user: user, code: code, state: state
        )
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["google_email"]).to eq(google_email)
        expect(response.parsed_body["data"]["google_calendar_connected"]).to be(true)
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "DELETE /api/v1/google_calendar/disconnect" do
    let(:headers) { {} }
    let(:user) do
      create(:user,
             google_uid: Faker::Number.number(digits: 21).to_s,
             google_email: Faker::Internet.email,
             google_access_token: "ya29.#{SecureRandom.hex(16)}",
             google_refresh_token: "1//#{SecureRandom.hex(16)}",
             google_token_expires_at: 30.minutes.from_now,
             google_token_scope: "https://www.googleapis.com/auth/calendar.readonly")
    end

    before do
      allow(Api::V1::GoogleCalendar::Disconnect).to receive(:call).and_call_original
      delete "/api/v1/google_calendar/disconnect", headers: headers
    end

    context "with a valid token" do
      let(:headers) { auth_headers_for(user) }

      it "calls Disconnect and returns :ok with user" do
        expect(Api::V1::GoogleCalendar::Disconnect).to have_received(:call).with(user: user)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["google_calendar_connected"]).to be(false)
        expect(response.parsed_body["data"]["google_email"]).to be_nil
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
