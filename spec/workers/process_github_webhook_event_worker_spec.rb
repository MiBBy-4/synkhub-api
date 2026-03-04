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
  end
end
