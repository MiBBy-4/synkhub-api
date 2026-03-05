# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Github::Repositories", type: :request do
  describe "GET /api/v1/github/repositories" do
    let(:user) { create(:user, github_uid: "12345", github_access_token: "gho_#{SecureRandom.hex(16)}") }
    let(:headers) { {} }
    let(:params) { {} }
    let(:repos_response) do
      [
        {
          "id" => 123,
          "full_name" => "org/repo",
          "name" => "repo",
          "private" => false,
          "owner" => { "login" => "org" },
        },
        {
          "id" => 456,
          "full_name" => "org/repo2",
          "name" => "repo2",
          "private" => true,
          "owner" => { "login" => "org" },
        },
      ]
    end

    before do
      api_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/user/repos") do
          [200, { "Content-Type" => "application/json" }, repos_response]
        end
      end

      allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
        method.call(*args) do |f|
          block&.call(f)
          f.adapter :test, api_stubs
        end
      end

      get "/api/v1/github/repositories", headers: headers, params: params
    end

    context "with a valid token" do
      let(:headers) { auth_headers_for(user) }

      it "returns repositories with pagination meta" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"].size).to eq(2)
        expect(response.parsed_body["data"].first["full_name"]).to eq("org/repo")
        meta = response.parsed_body["meta"]["pagination"]
        expect(meta).to include("current_page" => 1, "total_count" => 2)
      end
    end

    context "with custom page and limit" do
      let(:headers) { auth_headers_for(user) }
      let(:params) { { page: 1, limit: 1 } }

      it "returns paginated repositories" do
        expect(response).to have_http_status(:ok)
        data = response.parsed_body["data"]
        meta = response.parsed_body["meta"]["pagination"]
        expect(data.size).to eq(1)
        expect(meta["per_page"]).to eq(1)
        expect(meta["total_count"]).to eq(2)
        expect(meta["total_pages"]).to eq(2)
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
