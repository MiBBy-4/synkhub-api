# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::BaseHandler do
  let(:handler_class) { Api::V1::Github::Handlers::HandlePush }
  let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
  let(:repo_github_id) { rand(100_000..999_999) }
  let(:actor) { Faker::Internet.username }
  let(:event) do
    create(:github_webhook_event,
           event_type: "push",
           payload: {
             "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
             "sender" => { "login" => actor },
             "ref" => "refs/heads/main",
             "commits" => [],
             "compare" => "https://github.com/#{repo_full_name}/compare/abc...def",
           })
  end

  describe "#find_subscribed_users" do
    let(:subscribed_user) { create(:user) }
    let(:unsubscribed_user) { create(:user) }

    before do
      create(:github_repo_subscription, user: subscribed_user, github_repo_id: repo_github_id)
    end

    context "when there are subscribed users" do
      let(:result) { handler_class.call(event: event) }

      it "creates notifications only for subscribed users" do
        expect(result).to be_success
        expect(GithubNotification.where(user: subscribed_user).count).to eq(1)
        expect(GithubNotification.where(user: unsubscribed_user).count).to eq(0)
      end
    end
  end

  describe "#create_notifications! (idempotency)" do
    let(:user) { create(:user) }

    before do
      create(:github_repo_subscription, user: user, github_repo_id: repo_github_id)
      handler_class.call(event: event)
      handler_class.call(event: event)
    end

    it "does not create duplicate notifications for the same event" do
      expect(GithubNotification.where(user: user, github_webhook_event: event).count).to eq(1)
    end
  end
end
