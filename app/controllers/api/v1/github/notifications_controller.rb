# frozen_string_literal: true

module Api
  module V1
    module Github
      class NotificationsController < AuthenticatedController
        def index
          notifications = github_notifications_scope.newest_first
          notifications = notifications.where(event_type: filter_params[:event_type]) if filter_params[:event_type].present?
          notifications = notifications.where(repo_full_name: filter_params[:repo]) if filter_params[:repo].present?
          if filter_params[:read].present?
            notifications = notifications.where(read: ActiveModel::Type::Boolean.new.cast(filter_params[:read]))
          end

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

        def filter_params
          params.permit(:event_type, :repo, :read)
        end
      end
    end
  end
end
