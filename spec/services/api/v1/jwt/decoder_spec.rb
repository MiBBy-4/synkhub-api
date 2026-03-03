# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Jwt::Decoder do
  describe ".call" do
    let(:result) { described_class.call(token: token) }
    let(:user) { create(:user) }

    context "with a valid token" do
      let(:token) { Api::V1::Jwt::Encoder.call(user: user).value }

      it "returns success with the user" do
        expect(result).to be_success
        expect(result.value).to eq(user)
      end
    end

    context "with an expired token" do
      let(:token) do
        payload = { user_id: user.id, exp: 1.hour.ago.to_i }
        JWT.encode(payload, Rails.application.secret_key_base, "HS256")
      end

      it "returns Token has expired error" do
        expect(result).to be_error
        expect(result.error).to eq("Token has expired")
      end
    end

    context "with an invalid token" do
      let(:token) { Faker::Alphanumeric.alpha(number: 32) }

      it "returns Invalid token error" do
        expect(result).to be_error
        expect(result.error).to eq("Invalid token")
      end
    end

    context "when the user no longer exists" do
      let(:token) do
        payload = { user_id: -1, exp: 24.hours.from_now.to_i }
        JWT.encode(payload, Rails.application.secret_key_base, "HS256")
      end

      it "returns User not found error" do
        expect(result).to be_error
        expect(result.error).to eq("User not found")
      end
    end
  end
end
