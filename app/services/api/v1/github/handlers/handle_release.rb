# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandleRelease < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            release = payload["release"]
            release_name = release["name"] || release["tag_name"]
            title = "#{actor_login} published release #{release_name} in #{repo_full_name}"
            url = release["html_url"]

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
