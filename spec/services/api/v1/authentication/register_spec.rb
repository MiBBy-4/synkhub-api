# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Authentication::Register do
  describe ".call" do
    let(:result) { described_class.call(email: email, password: password, password_confirmation: password_confirmation) }
    let(:email) { Faker::Internet.email }
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:password_confirmation) { password }

    context "with valid params" do
      it "creates a user and returns success" do
        expect { result }.to change { User.count }.by(1)
        expect(result).to be_success
        expect(result.value).to be_a(User)
        expect(result.value.email).to eq(email)
      end
    end

    context "with mismatched password confirmation" do
      let(:password_confirmation) { Faker::Internet.password(min_length: 8) }

      it "returns password confirmation error" do
        expect(result).to be_error
        expect(result.error).to include("Password confirmation doesn't match Password")
      end
    end

    context "with a duplicate email" do
      before { create(:user, email: email) }

      it "returns email taken error" do
        expect(result).to be_error
        expect(result.error).to include("Email has already been taken")
      end
    end

    context "with an invalid email" do
      let(:email) { Faker::Lorem.word }

      it "returns email invalid error" do
        expect(result).to be_error
        expect(result.error).to include("Email is invalid")
      end
    end

    context "with a short password" do
      let(:password) { Faker::Internet.password(min_length: 2, max_length: 7) }

      it "returns password too short error" do
        expect(result).to be_error
        expect(result.error).to include("Password is too short")
      end
    end
  end
end
