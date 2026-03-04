# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Subscriptions::Destroy do
  describe ".call" do
    let(:user) { create(:user, github_uid: "12345", github_access_token: "gho_#{SecureRandom.hex(16)}") }
    let(:subscription) { create(:github_repo_subscription, user: user) }
    let(:result) { described_class.call(user: user, subscription_id: subscription.id) }

    before do
      api_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.delete("/repos/#{subscription.repo_full_name}/hooks/#{subscription.webhook_github_id}") do
          [204, {}, nil]
        end
      end

      allow(Faraday).to receive(:new).and_wrap_original do |method, *args, &block|
        method.call(*args) do |f|
          block&.call(f)
          f.adapter :test, api_stubs
        end
      end
    end

    context "with a valid subscription" do
      it "destroys the subscription and deletes the webhook" do
        subscription_id = subscription.id
        expect(result).to be_success
        expect(GithubRepoSubscription.find_by(id: subscription_id)).to be_nil
      end
    end

    context "with a non-existent subscription" do
      let(:result) { described_class.call(user: user, subscription_id: -1) }

      it "returns error" do
        expect(result).to be_error
        expect(result.error).to eq("Subscription not found")
      end
    end

    context "when subscription belongs to another user" do
      let(:other_user) { create(:user) }
      let(:other_subscription) { create(:github_repo_subscription, user: other_user) }
      let(:result) { described_class.call(user: user, subscription_id: other_subscription.id) }

      it "returns error" do
        expect(result).to be_error
        expect(result.error).to eq("Subscription not found")
      end
    end
  end
end
