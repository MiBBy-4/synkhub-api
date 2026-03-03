# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Registrations", type: :request do
  describe "POST /api/v1/signup" do
    let(:params) { { email: email, password: password, password_confirmation: password_confirmation } }
    let(:email) { Faker::Internet.email }
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:password_confirmation) { password }

    before do
      allow(Api::V1::Authentication::Register).to receive(:call).and_call_original
      post "/api/v1/signup", params: params
    end

    context "with valid params" do
      it "calls the Register service and returns :created with user and token" do
        expect(Api::V1::Authentication::Register).to have_received(:call).with(
          email: email, password: password, password_confirmation: password_confirmation
        )
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]["email"]).to eq(email)
        expect(response.parsed_body["data"]["token"]).to be_present
      end
    end

    context "with missing email" do
      let(:email) { nil }

      it { expect(response).to have_http_status(:unprocessable_content) }
    end

    context "with mismatched passwords" do
      let(:password_confirmation) { Faker::Internet.password(min_length: 8) }

      it { expect(response).to have_http_status(:unprocessable_content) }
    end

    context "with a duplicate email" do
      let(:email) { create(:user).email }

      it { expect(response).to have_http_status(:unprocessable_content) }
    end
  end
end
