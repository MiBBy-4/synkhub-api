# frozen_string_literal: true

class GithubCommitSerializer
  include Alba::Resource

  root_key :github_commit

  attributes :sha, :message, :author_name, :author_login, :url,
             :timestamp, :repo_full_name, :branch, :pusher
end
