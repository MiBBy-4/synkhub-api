# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Github::Commits", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:repo_id) { Faker::Number.number(digits: 6) }
  let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }

  describe "GET /api/v1/github/commits" do
    before do
      create(:github_repo_subscription, user: user, github_repo_id: repo_id, repo_full_name: repo_full_name)
      create(:github_webhook_event,
             event_type: "push",
             status: GithubWebhookEvent::PROCESSED_STATUS,
             payload: {
               "repository" => { "id" => repo_id, "full_name" => repo_full_name },
               "ref" => "refs/heads/main",
               "pusher" => { "name" => "dev" },
               "commits" => [
                 {
                   "id" => SecureRandom.hex(20),
                   "message" => Faker::Lorem.sentence,
                   "author" => { "name" => Faker::Name.name, "username" => Faker::Internet.username },
                   "url" => Faker::Internet.url,
                   "timestamp" => Time.current.iso8601,
                 },
                 {
                   "id" => SecureRandom.hex(20),
                   "message" => Faker::Lorem.sentence,
                   "author" => { "name" => Faker::Name.name, "username" => Faker::Internet.username },
                   "url" => Faker::Internet.url,
                   "timestamp" => 1.minute.ago.iso8601,
                 },
               ],
             })
      get "/api/v1/github/commits", headers: headers, params: params
    end

    let(:params) { {} }

    context "with a valid token" do
      it "returns commits with pagination meta" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        meta = response.parsed_body["meta"]["pagination"]
        expect(data.length).to eq(2)
        expect(data.first).to include("sha", "message", "repo_full_name", "branch")
        expect(meta).to include("current_page" => 1, "total_count" => 2)
      end
    end

    context "without a token" do
      let(:headers) { {} }

      it { expect(response).to have_http_status(:unauthorized) }
    end

    context "with custom page and limit" do
      let(:params) { { page: 1, limit: 1 } }

      it "returns paginated commits" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        meta = response.parsed_body["meta"]["pagination"]
        expect(data.length).to eq(1)
        expect(meta["per_page"]).to eq(1)
        expect(meta["total_count"]).to eq(2)
        expect(meta["total_pages"]).to eq(2)
      end
    end
  end
end
