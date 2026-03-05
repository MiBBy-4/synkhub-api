# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandleCheckRun < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            check_run = payload["check_run"]
            name = check_run["name"]
            conclusion = check_run["conclusion"]
            title = "Check '#{name}' completed (#{conclusion}) in #{repo_full_name}"
            url = check_run["html_url"]

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
