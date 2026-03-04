# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandlePush < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            branch = payload["ref"].to_s.sub("refs/heads/", "")
            commit_count = payload["commits"]&.size || 0
            title = "#{actor_login} pushed #{commit_count} commits to #{repo_full_name}:#{branch}"
            url = payload["compare"]

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
