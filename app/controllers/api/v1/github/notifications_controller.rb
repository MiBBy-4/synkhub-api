# frozen_string_literal: true

module Api
  module V1
    module Github
      class NotificationsController < AuthenticatedController
        include Pagy::Backend

        def index
          scope = github_notifications_scope.newest_first
          scope = scope.where(event_type: filter_params[:event_type]) if filter_params[:event_type].present?
          scope = scope.where(repo_full_name: filter_params[:repo]) if filter_params[:repo].present?
          if filter_params[:read].present?
            scope = scope.where(read: ActiveModel::Type::Boolean.new.cast(filter_params[:read]))
          end

          pagy, notifications = pagy(scope, **pagy_options)
          respond_with_query_results(pagy, notifications, serializer: GithubNotificationSerializer)
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

        def page_params
          params.permit(:page, :limit)
        end

        def pagy_options
          options = {}
          options[:page] = page_params[:page] if page_params[:page].present?
          options[:limit] = page_params[:limit] if page_params[:limit].present?
          options
        end
      end
    end
  end
end
