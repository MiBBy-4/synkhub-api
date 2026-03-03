# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Jwt::Encoder do
  describe ".call" do
    let(:result) { described_class.call(user: user) }
    let(:user) { create(:user) }

    it "returns a JWT token with user_id and expiration" do
      expect(result).to be_success
      expect(result.value).to be_a(String)
      expect(result.value.split(".").length).to eq(3)

      decoded = JWT.decode(result.value, Rails.application.secret_key_base, true, algorithm: "HS256").first
      expect(decoded["user_id"]).to eq(user.id)
      expect(decoded["exp"]).to be_within(5).of(24.hours.from_now.to_i)
    end
  end
end
