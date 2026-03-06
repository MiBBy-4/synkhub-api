# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :github_repo_subscriptions, dependent: :destroy
  has_many :github_notifications, dependent: :destroy
  has_one :user_preference, dependent: :destroy

  encrypts :github_access_token
  encrypts :google_access_token
  encrypts :google_refresh_token

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :github_uid, uniqueness: true, allow_nil: true
  validates :google_uid, uniqueness: true, allow_nil: true

  def github_connected?
    github_uid.present? && github_access_token.present?
  end

  def github_connected # rubocop:disable Naming/PredicateMethod
    github_connected?
  end

  def google_calendar_connected?
    google_uid.present? && google_refresh_token.present?
  end

  def google_calendar_connected # rubocop:disable Naming/PredicateMethod
    google_calendar_connected?
  end

  def google_token_expired?
    google_token_expires_at.present? && google_token_expires_at <= Time.current
  end

  private

  def password_required?
    password_digest_changed? || new_record?
  end
end
