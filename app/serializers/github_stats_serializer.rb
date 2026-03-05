# frozen_string_literal: true

class GithubStatsSerializer
  include Alba::Resource

  root_key :github_stats

  attributes :total, :unread, :by_event_type, :by_repo
end
