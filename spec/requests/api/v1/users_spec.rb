# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/me" do
    let(:headers) { {} }
    let(:user) { create(:user) }

    before { get "/api/v1/me", headers: headers }

    context "with a valid token" do
      let(:headers) { auth_headers_for(user) }

      it "returns :ok with the current user" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["id"]).to eq(user.id)
        expect(response.parsed_body["data"]["email"]).to eq(user.email)
      end
    end

    context "without a token" do
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context "with an invalid token" do
      let(:headers) { { "Authorization" => "Bearer #{Faker::Alphanumeric.alpha(number: 32)}" } }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
