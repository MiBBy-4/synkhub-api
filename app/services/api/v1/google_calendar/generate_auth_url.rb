# frozen_string_literal: true

module Api
  module V1
    module GoogleCalendar
      class GenerateAuthUrl < BaseService
        attr_reader :user

        SCOPES = [
          OPENID_SCOPE = "openid",
          EMAIL_SCOPE = "email",
          CALENDAR_READONLY_SCOPE = "https://www.googleapis.com/auth/calendar.readonly",
        ].freeze

        AUTHORIZATION_URL = "https://accounts.google.com/o/oauth2/v2/auth"

        def initialize(user:)
          @user = user
        end

        def call
          state = SecureRandom.hex(32)
          Rails.cache.write(cache_key, state, expires_in: 10.minutes)

          params = {
            client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
            redirect_uri: ENV.fetch("GOOGLE_REDIRECT_URI"),
            response_type: "code",
            scope: SCOPES.join(" "),
            access_type: "offline",
            prompt: "consent",
            state: state,
          }

          url = "#{AUTHORIZATION_URL}?#{params.to_query}"

          success(url)
        end

        private

        attr_writer :user

        def cache_key
          "google_oauth_state:#{user.id}"
        end
      end
    end
  end
end
