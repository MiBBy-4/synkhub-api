# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandleCreate < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            ref_type = payload["ref_type"]
            ref = payload["ref"]
            title = "#{actor_login} created #{ref_type} #{ref} in #{repo_full_name}"
            url = "https://github.com/#{repo_full_name}/tree/#{ref}"

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end
