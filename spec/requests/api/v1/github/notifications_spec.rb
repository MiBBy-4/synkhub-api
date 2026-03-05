# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Github::Notifications", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/github/notifications" do
    let(:repo_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:params) { {} }

    before do
      create(:github_notification, user: user, created_at: 2.days.ago)
      create(:github_notification, user: user, created_at: 1.day.ago)
      get "/api/v1/github/notifications", headers: headers, params: params
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

    context "with event_type filter" do
      let(:params) { { event_type: "push" } }

      before do
        create(:github_notification, user: user, event_type: "push")
        create(:github_notification, user: user, event_type: "issues")
        get "/api/v1/github/notifications", headers: headers, params: params
      end

      it "returns only matching event type" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data).to all(include("event_type" => "push"))
      end
    end

    context "with repo filter" do
      let(:params) { { repo: repo_name } }

      before do
        create(:github_notification, user: user, repo_full_name: repo_name)
        create(:github_notification, user: user, repo_full_name: "other/repo")
        get "/api/v1/github/notifications", headers: headers, params: params
      end

      it "returns only matching repo" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data).to all(include("repo_full_name" => repo_name))
      end
    end

    context "with read filter" do
      let(:params) { { read: "false" } }

      before do
        create(:github_notification, user: user, read: true)
        create(:github_notification, user: user, read: false)
        get "/api/v1/github/notifications", headers: headers, params: params
      end

      it "returns only unread notifications" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        expect(data).to all(include("read" => false))
      end
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
