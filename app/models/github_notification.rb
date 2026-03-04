# frozen_string_literal: true

class GithubNotification < ApplicationRecord
  belongs_to :user
  belongs_to :github_webhook_event

  validates :event_type, presence: true
  validates :title, presence: true
  validates :repo_full_name, presence: true
  validates :actor_login, presence: true

  scope :unread, -> { where(read: false) }
  scope :newest_first, -> { order(created_at: :desc) }

  def mark_read!
    update!(read: true)
  end
end
