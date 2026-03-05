# frozen_string_literal: true

class GithubRepoSubscriptionSerializer
  include Alba::Resource

  root_key :github_repo_subscription

  attributes :id, :github_repo_id, :repo_full_name, :created_at
end
