# frozen_string_literal: true

class GithubNotificationSerializer
  include Alba::Resource

  root_key :github_notification

  attributes :id, :event_type, :action, :title, :url,
             :repo_full_name, :actor_login, :read, :created_at
end
