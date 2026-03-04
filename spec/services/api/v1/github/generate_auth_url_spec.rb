# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::GenerateAuthUrl do
  describe ".call" do
    let(:result) { described_class.call(user: user) }
    let(:user) { create(:user) }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_ID").and_return("test_client_id")
      allow(ENV).to receive(:fetch).with("GITHUB_REDIRECT_URI").and_return("http://localhost:5173/github/callback")
    end

    context "with valid user" do
      before { result }

      it "returns success with a GitHub authorization URL" do
        expect(result).to be_success
        expect(result.value).to include("https://github.com/login/oauth/authorize")
        expect(result.value).to include("client_id=test_client_id")
        expect(result.value).to include("redirect_uri=")
        expect(result.value).to include("scope=")
        expect(result.value).to include("state=")
      end

      it "stores the state in the cache" do
        expect(Rails.cache.read("github_oauth_state:#{user.id}")).to be_present
      end
    end
  end
end
