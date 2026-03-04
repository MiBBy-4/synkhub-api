# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Github::Notifications", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/github/notifications" do
    before do
      create(:github_notification, user: user, created_at: 2.days.ago)
      create(:github_notification, user: user, created_at: 1.day.ago)
      get "/api/v1/github/notifications", headers: headers
    end

    context "with a valid token" do
      it "returns notifications newest first" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data.size).to eq(2)
        expect(data.first["created_at"]).to be > data.last["created_at"]
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "PATCH /api/v1/github/notifications/:id/read" do
    let(:notification) { create(:github_notification, user: user, read: false) }

    before do
      patch "/api/v1/github/notifications/#{notification.id}/read", headers: headers
    end

    context "with a valid token" do
      it "marks the notification as read" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["read"]).to be(true)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe "PATCH /api/v1/github/notifications/read_all" do
    before do
      create(:github_notification, user: user, read: false)
      create(:github_notification, user: user, read: false)
      patch "/api/v1/github/notifications/read_all", headers: headers
    end

    context "with a valid token" do
      it "marks all notifications as read" do
        expect(response).to have_http_status(:no_content)
        expect(user.github_notifications.unread.count).to eq(0)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
