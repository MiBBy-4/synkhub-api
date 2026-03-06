# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::GoogleCalendar::Disconnect do
  describe ".call" do
    let(:result) { described_class.call(user: user) }
    let(:user) do
      create(:user,
             google_uid: Faker::Number.number(digits: 21).to_s,
             google_email: Faker::Internet.email,
             google_access_token: "ya29.#{SecureRandom.hex(16)}",
             google_refresh_token: "1//#{SecureRandom.hex(16)}",
             google_token_expires_at: 30.minutes.from_now,
             google_token_scope: "https://www.googleapis.com/auth/calendar.readonly")
    end

    context "with a connected user" do
      before do
        result
        user.reload
      end

      it "clears all Google Calendar fields and returns success" do
        expect(result).to be_success
        expect(result.value).to eq(user)
        expect(user.google_uid).to be_nil
        expect(user.google_email).to be_nil
        expect(user.google_access_token).to be_nil
        expect(user.google_refresh_token).to be_nil
        expect(user.google_token_expires_at).to be_nil
        expect(user.google_token_scope).to be_nil
        expect(user.google_calendar_connected?).to be(false)
      end
    end
  end
end
