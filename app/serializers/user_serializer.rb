# frozen_string_literal: true

class UserSerializer
  include Alba::Resource

  root_key :user

  attributes :id, :email, :github_username, :github_connected, :google_email, :google_calendar_connected
end
