# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandleCheckSuite < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            check_suite = payload["check_suite"]
            conclusion = check_suite["conclusion"]
            title = "Check suite completed (#{conclusion}) in #{repo_full_name}"
            repo_url = payload.dig("repository", "html_url")
            url = "#{repo_url}/actions"

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
