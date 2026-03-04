# frozen_string_literal: true

class UserSerializer
  include Alba::Resource

  root_key :user

  attributes :id, :email, :github_username, :github_connected
end
