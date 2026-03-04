# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubNotification, type: :model do
  subject { build(:github_notification) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:github_webhook_event) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:repo_full_name) }
    it { is_expected.to validate_presence_of(:actor_login) }
  end

  describe "scopes" do
    describe ".unread" do
      let(:unread_notification) { create(:github_notification, read: false) }
      let(:read_notification) { create(:github_notification, read: true) }

      it "returns only unread notifications" do
        expect(described_class.unread).to include(unread_notification)
        expect(described_class.unread).not_to include(read_notification)
      end
    end

    describe ".newest_first" do
      let(:older_notification) { create(:github_notification, created_at: 2.days.ago) }
      let(:newer_notification) { create(:github_notification, created_at: 1.day.ago) }

      it "returns notifications ordered by created_at descending" do
        expect(described_class.newest_first).to eq([newer_notification, older_notification])
      end
    end
  end

  describe "#mark_read!" do
    let(:notification) { create(:github_notification, read: false) }

    before do
      notification.mark_read!
      notification.reload
    end

    it "sets read to true" do
      expect(notification.read).to be(true)
    end
  end
end
