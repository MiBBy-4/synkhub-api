# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandleIssueComment < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            issue = payload["issue"]
            number = issue["number"]
            title = "#{actor_login} commented on issue ##{number} in #{repo_full_name}"
            url = payload.dig("comment", "html_url")

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
