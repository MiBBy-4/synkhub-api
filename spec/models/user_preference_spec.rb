# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPreference, type: :model do
  subject(:preference) { build(:user_preference) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:email_digest_frequency).in_array(["daily", "weekly"]) }

    context "with valid notification_event_types" do
      before { preference.notification_event_types = ["push", "issues"] }

      it "is valid" do
        expect(preference).to be_valid
      end
    end

    context "with invalid notification_event_types" do
      before { preference.notification_event_types = ["push", "invalid_event"] }

      it "is invalid" do
        expect(preference).not_to be_valid
        expect(preference.errors[:notification_event_types]).to be_present
      end
    end
  end
end
