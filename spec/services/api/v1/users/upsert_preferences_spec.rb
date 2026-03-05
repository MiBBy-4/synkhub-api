# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Users::UpsertPreferences do
  describe ".call" do
    let(:result) { described_class.call(user: user, params: params) }
    let(:user) { create(:user) }

    context "when creating new preferences" do
      let(:params) { { notification_event_types: ["push", "issues"], email_digest_enabled: true, email_digest_frequency: "daily" } }

      it "creates preferences and returns success" do
        expect(result).to be_success
        expect(result.value.notification_event_types).to eq(["push", "issues"])
        expect(result.value.email_digest_enabled).to be(true)
        expect(result.value.email_digest_frequency).to eq("daily")
      end
    end

    context "when updating existing preferences" do
      let(:params) { { email_digest_enabled: true } }

      before do
        create(:user_preference, user: user, notification_event_types: ["push"])
      end

      it "updates preferences and returns success" do
        expect(result).to be_success
        expect(result.value.email_digest_enabled).to be(true)
        expect(result.value.notification_event_types).to eq(["push"])
      end
    end

    context "with invalid params" do
      let(:params) { { email_digest_frequency: "monthly" } }

      it "returns failure" do
        expect(result).to be_error
      end
    end
  end
end
