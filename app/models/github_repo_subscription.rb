# frozen_string_literal: true

class GithubRepoSubscription < ApplicationRecord
  belongs_to :user

  validates :github_repo_id, presence: true, uniqueness: { scope: :user_id }
  validates :repo_full_name, presence: true
end
