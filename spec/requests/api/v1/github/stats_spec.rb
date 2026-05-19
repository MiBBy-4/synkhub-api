# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Github::Stats", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/github/stats" do
    before do
      create(:github_notification, user: user, event_type: "push", read: false)
      create(:github_notification, user: user, event_type: "issues", read: true)
      get "/api/v1/github/stats", headers: headers
    end

    context "with a valid token" do
      it "returns stats with correct totals and breakdowns" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data["total"]).to eq(2)
        expect(data["unread"]).to eq(1)
        expect(data["by_event_type"]).to include("push" => 1, "issues" => 1)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
