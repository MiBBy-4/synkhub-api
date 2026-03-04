# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Disconnect do
  describe ".call" do
    let(:result) { described_class.call(user: user) }
    let(:user) do
      create(:user,
             github_uid: Faker::Number.number(digits: 8).to_s,
             github_username: Faker::Internet.username,
             github_access_token: "gho_#{SecureRandom.hex(16)}",
             github_token_scope: "repo,read:user")
    end

    context "with a connected user" do
      before do
        result
        user.reload
      end

      it "clears all GitHub fields and returns success" do
        expect(result).to be_success
        expect(result.value).to eq(user)
        expect(user.github_uid).to be_nil
        expect(user.github_username).to be_nil
        expect(user.github_access_token).to be_nil
        expect(user.github_token_scope).to be_nil
        expect(user.github_connected?).to be(false)
      end
    end
  end
end
