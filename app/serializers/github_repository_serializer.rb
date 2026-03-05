# frozen_string_literal: true

class GithubRepositorySerializer
  include Alba::Resource

  root_key :github_repository

  attributes :id, :full_name, :name, :private, :owner_login
end
