# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubWebhookEvent, type: :model do
  subject { build(:github_webhook_event) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(described_class::SUPPORTED_EVENTS) }
    it { is_expected.to validate_presence_of(:delivery_id) }
    it { is_expected.to validate_uniqueness_of(:delivery_id) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe "scopes" do
    describe ".pending" do
      let(:pending_event) { create(:github_webhook_event, status: described_class::PENDING_STATUS) }
      let(:processed_event) { create(:github_webhook_event, status: described_class::PROCESSED_STATUS) }

      it "returns only pending events" do
        expect(described_class.pending).to include(pending_event)
        expect(described_class.pending).not_to include(processed_event)
      end
    end

    describe ".failed" do
      let(:failed_event) { create(:github_webhook_event, status: described_class::FAILED_STATUS) }
      let(:pending_event) { create(:github_webhook_event, status: described_class::PENDING_STATUS) }

      it "returns only failed events" do
        expect(described_class.failed).to include(failed_event)
        expect(described_class.failed).not_to include(pending_event)
      end
    end
  end

  describe "#mark_processing!" do
    let(:event) { create(:github_webhook_event, status: described_class::PENDING_STATUS) }

    before do
      event.mark_processing!
      event.reload
    end

    it "updates status to processing" do
      expect(event.status).to eq(described_class::PROCESSING_STATUS)
    end
  end

  describe "#mark_processed!" do
    let(:event) { create(:github_webhook_event, status: described_class::PROCESSING_STATUS) }

    before do
      freeze_time do
        event.mark_processed!
        event.reload
      end
    end

    it "updates status to processed and sets processed_at" do
      expect(event.status).to eq(described_class::PROCESSED_STATUS)
      expect(event.processed_at).to be_present
    end
  end

  describe "#mark_failed!" do
    let(:event) { create(:github_webhook_event, status: described_class::PROCESSING_STATUS) }
    let(:message) { Faker::Lorem.sentence }

    before do
      event.mark_failed!(message)
      event.reload
    end

    it "updates status to failed and sets error_message" do
      expect(event.status).to eq(described_class::FAILED_STATUS)
      expect(event.error_message).to eq(message)
    end
  end
end
