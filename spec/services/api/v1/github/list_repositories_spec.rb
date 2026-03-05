# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::ListRepositories do
  describe ".call" do
    let(:user) { create(:user, github_uid: "12345", github_access_token: "gho_#{SecureRandom.hex(16)}") }
    let(:result) { described_class.call(user: user) }
    let(:repos_response) do
      [
        {
          "id" => 123,
          "full_name" => "org/repo-one",
          "name" => "repo-one",
          "private" => false,
          "owner" => { "login" => "org" },
        },
        {
          "id" => 456,
          "full_name" => "org/repo-two",
          "name" => "repo-two",
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
    end

    context "with a connected GitHub account" do
      it "returns success with normalized repos" do
        expect(result).to be_success
        expect(result.value.size).to eq(2)
        expect(result.value.first).to eq({
                                           id: 123,
                                           full_name: "org/repo-one",
                                           name: "repo-one",
                                           private: false,
                                           owner_login: "org",
                                         })
      end
    end

    context "without a connected GitHub account" do
      let(:user) { create(:user) }

      it "returns error" do
        expect(result).to be_error
        expect(result.error).to eq("GitHub account not connected")
      end
    end
  end
end
