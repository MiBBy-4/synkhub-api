# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid").for(:email) }
    it { is_expected.to have_secure_password }
    it { is_expected.to validate_uniqueness_of(:github_uid).allow_nil }
    it { is_expected.to validate_uniqueness_of(:google_uid).allow_nil }
  end

  describe "#github_connected?" do
    let(:user) { build(:user) }

    context "when github_uid and github_access_token are present" do
      before do
        user.github_uid = Faker::Number.number(digits: 8).to_s
        user.github_access_token = "gho_#{SecureRandom.hex(16)}"
      end

      it "returns true" do
        expect(user.github_connected?).to be(true)
      end
    end

    context "when github_uid is nil" do
      it "returns false" do
        expect(user.github_connected?).to be(false)
      end
    end

    context "when github_access_token is nil" do
      before { user.github_uid = Faker::Number.number(digits: 8).to_s }

      it "returns false" do
        expect(user.github_connected?).to be(false)
      end
    end
  end

  describe "#google_calendar_connected?" do
    let(:user) { build(:user) }

    context "when google_uid and google_refresh_token are present" do
      before do
        user.google_uid = Faker::Number.number(digits: 21).to_s
        user.google_refresh_token = "1//#{SecureRandom.hex(16)}"
      end

      it "returns true" do
        expect(user.google_calendar_connected?).to be(true)
      end
    end

    context "when google_uid is nil" do
      it "returns false" do
        expect(user.google_calendar_connected?).to be(false)
      end
    end

    context "when google_refresh_token is nil" do
      before { user.google_uid = Faker::Number.number(digits: 21).to_s }

      it "returns false" do
        expect(user.google_calendar_connected?).to be(false)
      end
    end
  end

  describe "#google_token_expired?" do
    let(:user) { build(:user) }

    context "when token expires_at is in the past" do
      before { user.google_token_expires_at = 1.hour.ago }

      it "returns true" do
        expect(user.google_token_expired?).to be(true)
      end
    end

    context "when token expires_at is in the future" do
      before { user.google_token_expires_at = 30.minutes.from_now }

      it "returns false" do
        expect(user.google_token_expired?).to be(false)
      end
    end

    context "when token expires_at is nil" do
      it "returns false" do
        expect(user.google_token_expired?).to be(false)
      end
    end
  end
end
