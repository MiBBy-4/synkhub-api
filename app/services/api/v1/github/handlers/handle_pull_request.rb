# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandlePullRequest < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            pr = payload["pull_request"]
            number = pr["number"]
            pr_title = pr["title"]
            action = payload["action"]

            verb = if action == "closed" && pr["merged"]
                     "merged"
                   else
                     action
                   end

            title = "#{actor_login} #{verb} PR ##{number}: #{pr_title} in #{repo_full_name}"
            url = pr["html_url"]

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
