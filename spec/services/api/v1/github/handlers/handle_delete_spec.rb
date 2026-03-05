# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandleDelete do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:ref_type) { "branch" }
    let(:ref) { "feature-x" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "delete",
             payload: {
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
               "sender" => { "login" => actor },
               "ref_type" => ref_type,
               "ref" => ref,
             })
    end
    let(:user) { create(:user) }
    let(:result) { described_class.call(event: event) }

    before do
      create(:github_repo_subscription, user: user, github_repo_id: repo_github_id)
    end

    context "when branch is deleted" do
      it "creates notification with branch title" do
        expect(result).to be_success
        notification = GithubNotification.last
        expect(notification.title).to eq("#{actor} deleted branch #{ref} in #{repo_full_name}")
        expect(notification.url).to eq("https://github.com/#{repo_full_name}")
      end
    end

    context "when tag is deleted" do
      let(:ref_type) { "tag" }
      let(:ref) { "v1.0" }

      it "creates notification with tag title" do
        expect(result).to be_success
        expect(GithubNotification.last.title).to eq("#{actor} deleted tag #{ref} in #{repo_full_name}")
      end
    end
  end
end
