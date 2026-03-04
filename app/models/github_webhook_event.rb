# frozen_string_literal: true

class GithubWebhookEvent < ApplicationRecord
  STATUSES = [
    PENDING_STATUS = "pending",
    PROCESSING_STATUS = "processing",
    PROCESSED_STATUS = "processed",
    FAILED_STATUS = "failed",
  ].freeze

  SUPPORTED_EVENTS = [
    "push",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
    "issues",
    "issue_comment",
    "check_run",
    "check_suite",
    "create",
    "delete",
    "release",
    "workflow_run",
  ].freeze

  validates :event_type, presence: true, inclusion: { in: SUPPORTED_EVENTS }
  validates :delivery_id, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: PENDING_STATUS) }
  scope :failed, -> { where(status: FAILED_STATUS) }

  def mark_processing!
    update!(status: PROCESSING_STATUS)
  end

  def mark_processed!
    update!(status: PROCESSED_STATUS, processed_at: Time.current)
  end

  def mark_failed!(message)
    update!(status: FAILED_STATUS, error_message: message)
  end
end
