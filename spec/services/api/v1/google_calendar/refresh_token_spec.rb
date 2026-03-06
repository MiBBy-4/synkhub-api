# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::GoogleCalendar::RefreshToken do
  describe ".call" do
    let(:result) { described_class.call(user: user) }
    let(:new_access_token) { "ya29.#{SecureRandom.hex(16)}" }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return("test_google_client_id")
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_SECRET").and_return("test_google_secret")

      token_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/token") do
          [200, { "Content-Type" => "application/json" }, {
            "access_token" => new_access_token,
            "expires_in" => 3599,
            "token_type" => "Bearer",
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

    context "when token is expired" do
      let(:user) do
        create(:user,
               google_uid: Faker::Number.number(digits: 21).to_s,
               google_email: Faker::Internet.email,
               google_access_token: "ya29.#{SecureRandom.hex(16)}",
               google_refresh_token: "1//#{SecureRandom.hex(16)}",
               google_token_expires_at: 1.hour.ago,
               google_token_scope: "https://www.googleapis.com/auth/calendar.readonly")
      end

      before do
        result
        user.reload
      end

      it "refreshes the access token and returns success" do
        expect(result).to be_success
        expect(result.value).to eq(user)
        expect(user.google_access_token).to eq(new_access_token)
        expect(user.google_token_expires_at).to be > Time.current
      end
    end

    context "when token is not expired" do
      let(:user) do
        create(:user,
               google_uid: Faker::Number.number(digits: 21).to_s,
               google_email: Faker::Internet.email,
               google_access_token: "ya29.#{SecureRandom.hex(16)}",
               google_refresh_token: "1//#{SecureRandom.hex(16)}",
               google_token_expires_at: 30.minutes.from_now,
               google_token_scope: "https://www.googleapis.com/auth/calendar.readonly")
      end

      it "returns success without refreshing" do
        expect(result).to be_success
        expect(result.value).to eq(user)
      end
    end

    context "when Google Calendar is not connected" do
      let(:user) { create(:user) }

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Google Calendar is not connected")
      end
    end

    context "when refresh fails" do
      let(:user) do
        create(:user,
               google_uid: Faker::Number.number(digits: 21).to_s,
               google_email: Faker::Internet.email,
               google_access_token: "ya29.#{SecureRandom.hex(16)}",
               google_refresh_token: "1//#{SecureRandom.hex(16)}",
               google_token_expires_at: 1.hour.ago,
               google_token_scope: "https://www.googleapis.com/auth/calendar.readonly")
      end

      before do
        failed_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("/token") do
            [400, { "Content-Type" => "application/json" }, { "error" => "invalid_grant" }]
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
        expect(result.error).to eq("Failed to refresh access token")
      end
    end
  end
end
