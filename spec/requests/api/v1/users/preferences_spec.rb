# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::Preferences", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/users/preferences" do
    before do
      get "/api/v1/users/preferences", headers: headers
    end

    context "with a valid token and no existing preferences" do
      it "returns default preferences" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data["notification_event_types"]).to eq(GithubWebhookEvent::SUPPORTED_EVENTS)
        expect(data["email_digest_enabled"]).to be(false)
        expect(data["email_digest_frequency"]).to eq("weekly")
      end
    end

    context "with existing preferences" do
      before do
        create(:user_preference, user: user, notification_event_types: ["push"], email_digest_enabled: true)
        get "/api/v1/users/preferences", headers: headers
      end

      it "returns saved preferences" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data["notification_event_types"]).to eq(["push"])
        expect(data["email_digest_enabled"]).to be(true)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "PATCH /api/v1/users/preferences" do
    let(:params) { { notification_event_types: ["push", "issues"], email_digest_enabled: true, email_digest_frequency: "daily" } }

    before do
      patch "/api/v1/users/preferences", params: params, headers: headers
    end

    context "with valid params" do
      it "creates/updates preferences" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data["notification_event_types"]).to eq(["push", "issues"])
        expect(data["email_digest_enabled"]).to be(true)
        expect(data["email_digest_frequency"]).to eq("daily")
      end
    end

    context "with invalid event types" do
      let(:params) { { notification_event_types: ["invalid_event"] } }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
