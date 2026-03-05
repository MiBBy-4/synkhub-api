# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessGithubWebhookEventWorker do
  describe "#perform" do
    let(:event) { create(:github_webhook_event, status: GithubWebhookEvent::PENDING_STATUS) }

    context "with a pending event" do
      before do
        described_class.new.perform(event.id)
        event.reload
      end

      it "marks the event as processed" do
        expect(event.status).to eq(GithubWebhookEvent::PROCESSED_STATUS)
        expect(event.processed_at).to be_present
      end
    end

    context "with an already processed event" do
      let(:event) { create(:github_webhook_event, status: GithubWebhookEvent::PROCESSED_STATUS) }

      before do
        described_class.new.perform(event.id)
        event.reload
      end

      it "skips processing" do
        expect(event.status).to eq(GithubWebhookEvent::PROCESSED_STATUS)
      end
    end

    context "with a processing event (retry after crash)" do
      let(:event) { create(:github_webhook_event, status: GithubWebhookEvent::PROCESSING_STATUS) }

      before do
        described_class.new.perform(event.id)
        event.reload
      end

      it "reprocesses the event" do
        expect(event.status).to eq(GithubWebhookEvent::PROCESSED_STATUS)
        expect(event.processed_at).to be_present
      end
    end

    context "when dispatching to handler" do
      let(:event) { create(:github_webhook_event, event_type: "push", status: GithubWebhookEvent::PENDING_STATUS) }
      let(:handler_instance) { instance_double(Api::V1::Github::Handlers::HandlePush, call: nil, success?: true, error?: false, value: nil, error: nil) }

      before do
        allow(Api::V1::Github::Handlers::HandlePush).to receive(:call).and_return(handler_instance)
        described_class.new.perform(event.id)
        event.reload
      end

      it "dispatches to the correct handler" do
        expect(Api::V1::Github::Handlers::HandlePush).to have_received(:call).with(event: event)
        expect(event.status).to eq(GithubWebhookEvent::PROCESSED_STATUS)
      end
    end

    context "when handler returns an error" do
      let(:event) { create(:github_webhook_event, event_type: "push", status: GithubWebhookEvent::PENDING_STATUS) }
      let(:handler_instance) { instance_double(Api::V1::Github::Handlers::HandlePush, call: nil, success?: false, error?: true, value: nil, error: "Handler failed") }

      before do
        allow(Api::V1::Github::Handlers::HandlePush).to receive(:call).and_return(handler_instance)
      end

      it "raises the error" do
        expect { described_class.new.perform(event.id) }.to raise_error(RuntimeError, "Handler failed")
      end
    end
  end
end
