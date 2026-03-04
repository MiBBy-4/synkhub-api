# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandleIssues < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            issue = payload["issue"]
            number = issue["number"]
            issue_title = issue["title"]
            action = payload["action"]
            title = "#{actor_login} #{action} issue ##{number}: #{issue_title} in #{repo_full_name}"
            url = issue["html_url"]

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
