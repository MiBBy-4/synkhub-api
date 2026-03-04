# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Webhooks::IngestGithubEvent do
  describe ".call" do
    let(:result) { described_class.call(event_type: event_type, delivery_id: delivery_id, payload: payload) }
    let(:event_type) { "push" }
    let(:delivery_id) { SecureRandom.uuid }
    let(:payload) { { "ref" => "refs/heads/main", "repository" => { "full_name" => "org/repo" } } }

    before do
      allow(ProcessGithubWebhookEventWorker).to receive(:perform_async)
    end

    context "with a valid event" do
      it "creates a GithubWebhookEvent and enqueues a job" do
        expect { result }.to change { GithubWebhookEvent.count }.by(1)
        expect(result).to be_success
        expect(result.value).to be_a(GithubWebhookEvent)
        expect(result.value.event_type).to eq("push")
        expect(result.value.delivery_id).to eq(delivery_id)
        expect(result.value.status).to eq("pending")
        expect(ProcessGithubWebhookEventWorker).to have_received(:perform_async).with(result.value.id)
      end
    end

    context "with an event that has an action" do
      let(:event_type) { "pull_request" }
      let(:payload) { { "action" => "opened", "pull_request" => {} } }

      it "extracts the action from the payload" do
        expect(result).to be_success
        expect(result.value.action).to eq("opened")
      end
    end

    context "with an unsupported event type" do
      let(:event_type) { "unsupported_event" }

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Unsupported event type: unsupported_event")
      end
    end

    context "with a duplicate delivery_id" do
      let(:existing_event) { create(:github_webhook_event, delivery_id: delivery_id, event_type: "push") }

      before { existing_event }

      it "returns the existing event" do
        expect { result }.not_to(change { GithubWebhookEvent.count })
        expect(result).to be_success
        expect(result.value).to eq(existing_event)
      end
    end
  end
end
