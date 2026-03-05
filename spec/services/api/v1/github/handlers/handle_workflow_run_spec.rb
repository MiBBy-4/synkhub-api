# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Github::Handlers::HandleWorkflowRun do
  describe ".call" do
    let(:repo_full_name) { "#{Faker::Internet.username}/#{Faker::App.name.parameterize}" }
    let(:repo_github_id) { rand(100_000..999_999) }
    let(:actor) { Faker::Internet.username }
    let(:workflow_name) { "CI" }
    let(:conclusion) { "success" }
    let(:workflow_url) { "https://github.com/#{repo_full_name}/actions/runs/1" }
    let(:event) do
      create(:github_webhook_event,
             event_type: "workflow_run",
             action: "completed",
             payload: {
               "action" => "completed",
               "repository" => { "full_name" => repo_full_name, "id" => repo_github_id },
               "sender" => { "login" => actor },
               "workflow_run" => { "name" => workflow_name, "conclusion" => conclusion, "html_url" => workflow_url },
             })
    end
    let(:user) { create(:user) }
    let(:result) { described_class.call(event: event) }

    before do
      create(:github_repo_subscription, user: user, github_repo_id: repo_github_id)
    end

    it "creates a notification with correct title and url" do
      expect(result).to be_success
      notification = GithubNotification.last
      expect(notification.title).to eq("Workflow '#{workflow_name}' completed (#{conclusion}) in #{repo_full_name}")
      expect(notification.url).to eq(workflow_url)
    end
  end
end
