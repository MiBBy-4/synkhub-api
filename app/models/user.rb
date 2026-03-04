# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  encrypts :github_access_token

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :github_uid, uniqueness: true, allow_nil: true

  def github_connected?
    github_uid.present? && github_access_token.present?
  end

  def github_connected # rubocop:disable Naming/PredicateMethod
    github_connected?
  end

  private

  def password_required?
    password_digest_changed? || new_record?
  end
end
