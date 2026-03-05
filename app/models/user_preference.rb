# frozen_string_literal: true

class UserPreference < ApplicationRecord
  belongs_to :user

  validates :email_digest_frequency, inclusion: { in: ["daily", "weekly"] }
  validate :validate_notification_event_types

  private

  def validate_notification_event_types
    return if notification_event_types.blank?

    invalid = notification_event_types - GithubWebhookEvent::SUPPORTED_EVENTS
    return if invalid.empty?

    errors.add(:notification_event_types, "contains unsupported event types: #{invalid.join(', ')}")
  end
end
