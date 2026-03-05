# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandlePullRequestReview < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            pr = payload["pull_request"]
            number = pr["number"]
            title = "#{actor_login} reviewed PR ##{number} in #{repo_full_name}"
            url = payload.dig("review", "_links", "html", "href") || pr["html_url"]

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
