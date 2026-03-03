# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/login" do
    let(:params) { { email: email, password: password } }
    let(:email) { user.email }
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:user) { create(:user, password: password) }

    before do
      allow(Api::V1::Authentication::Authenticate).to receive(:call).and_call_original
      post "/api/v1/login", params: params
    end

    context "with valid credentials" do
      it "calls the Authenticate service and returns :ok with user and token" do
        expect(Api::V1::Authentication::Authenticate).to have_received(:call).with(
          email: email, password: password
        )
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["id"]).to eq(user.id)
        expect(response.parsed_body["data"]["email"]).to eq(user.email)
        expect(response.parsed_body["data"]["token"]).to be_present
      end
    end

    context "with wrong password" do
      let(:password) { Faker::Internet.password(min_length: 8) }
      let(:user) { create(:user) }

      it "returns :unauthorized with error" do
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("Invalid email or password")
      end
    end

    context "with non-existent email" do
      let(:email) { Faker::Internet.email }
      let(:user) { create(:user) }

      it "returns :unauthorized with error" do
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("User not found")
      end
    end
  end
end
