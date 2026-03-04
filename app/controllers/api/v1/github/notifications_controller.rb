# frozen_string_literal: true

module Api
  module V1
    module Github
      class NotificationsController < AuthenticatedController
        def index
          notifications = github_notifications_scope.newest_first

          respond_with_serialized_resources_collection(notifications, serializer: GithubNotificationSerializer)
        end

        def read
          notification = github_notifications_scope.find(params[:id])
          notification.mark_read!

          respond_with_serialized_resource(notification, serializer: GithubNotificationSerializer)
        end

        def read_all
          github_notifications_scope.unread.update_all(read: true)

          head :no_content
        end

        private

        def github_notifications_scope
          current_user.github_notifications
        end
      end
    end
  end
end
