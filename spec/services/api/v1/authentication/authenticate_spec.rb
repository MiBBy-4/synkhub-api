# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Authentication::Authenticate do
  describe ".call" do
    let(:result) { described_class.call(email: email, password: password) }
    let(:email) { user.email }
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:user) { create(:user, password: password) }

    context "with valid credentials" do
      it "returns success with the user" do
        expect(result).to be_success
        expect(result.value).to eq(user)
      end
    end

    context "with wrong password" do
      let(:password) { Faker::Internet.password(min_length: 8) }
      let(:user) { create(:user) }

      it "returns Invalid email or password error" do
        expect(result).to be_error
        expect(result.error).to eq("Invalid email or password")
      end
    end

    context "with non-existent email" do
      let(:email) { Faker::Internet.email }
      let(:user) { create(:user) }

      it "returns User not found error" do
        expect(result).to be_error
        expect(result.error).to eq("User not found")
      end
    end
  end
end
