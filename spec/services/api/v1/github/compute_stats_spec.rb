# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::ComputeStats do
  describe ".call" do
    let(:result) { described_class.call(user: user) }
    let(:user) { create(:user) }

    context "with no notifications" do
      it "returns zero stats" do
        expect(result).to be_success
        expect(result.value.total).to eq(0)
        expect(result.value.unread).to eq(0)
        expect(result.value.by_event_type).to eq({})
        expect(result.value.by_repo).to eq({})
      end
    end

    context "with notifications" do
      let(:repo_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }

      before do
        create(:github_notification, user: user, event_type: "push", repo_full_name: repo_name, read: false)
        create(:github_notification, user: user, event_type: "push", repo_full_name: repo_name, read: true)
        create(:github_notification, user: user, event_type: "issues", repo_full_name: repo_name, read: false)
      end

      it "returns correct counts and breakdowns" do
        expect(result).to be_success
        expect(result.value.total).to eq(3)
        expect(result.value.unread).to eq(2)
        expect(result.value.by_event_type).to eq({ "push" => 2, "issues" => 1 })
        expect(result.value.by_repo).to eq({ repo_name => 3 })
      end
    end
  end
end
