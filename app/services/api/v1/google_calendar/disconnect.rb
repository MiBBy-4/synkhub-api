# frozen_string_literal: true

module Api
  module V1
    module GoogleCalendar
      class Disconnect < BaseService
        attr_reader :user

        def initialize(user:)
          @user = user
        end

        def call
          user.update!(
            google_uid: nil,
            google_email: nil,
            google_access_token: nil,
            google_refresh_token: nil,
            google_token_expires_at: nil,
            google_token_scope: nil
          )

          success(user)
        end

        private

        attr_writer :user
      end
    end
  end
end
