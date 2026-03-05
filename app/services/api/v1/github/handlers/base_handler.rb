# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class BaseHandler < BaseService
          attr_reader :event

          def initialize(event:)
            @event = event
          end

          private

          attr_writer :event

          def payload
            event.payload
          end

          def repo_full_name
            payload.dig("repository", "full_name")
          end

          def repo_github_id
            payload.dig("repository", "id")
          end

          def actor_login
            payload.dig("sender", "login")
          end

          def find_subscribed_users
            User.joins(:github_repo_subscriptions)
                .where(github_repo_subscriptions: { github_repo_id: repo_github_id })
          end

          def create_notifications!(users, title:, url:)
            users.filter_map do |user|
              next unless user_wants_event?(user, event.event_type)

              GithubNotification.find_or_create_by!(
                user: user,
                github_webhook_event: event
              ) do |notification|
                notification.event_type = event.event_type
                notification.action = event.action
                notification.title = title
                notification.url = url
                notification.repo_full_name = repo_full_name
                notification.actor_login = actor_login
              end
            end
          end

          def user_wants_event?(user, event_type)
            preference = user.user_preference
            return true unless preference

            preference.notification_event_types.include?(event_type)
          end
        end
      end
    end
  end
end
