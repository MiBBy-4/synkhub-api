# frozen_string_literal: true

module Api
  module V1
    module Github
      class ComputeStats < BaseService
        attr_reader :user

        Result = Data.define(:total, :unread, :by_event_type, :by_repo)

        def initialize(user:)
          @user = user
        end

        def call
          notifications = user.github_notifications
          total = notifications.count
          unread = notifications.unread.count
          by_event_type = notifications.group(:event_type).count
          by_repo = notifications.group(:repo_full_name).count

          success(
            Result.new(
              total: total,
              unread: unread,
              by_event_type: by_event_type,
              by_repo: by_repo
            )
          )
        end

        private

        attr_writer :user
      end
    end
  end
end
