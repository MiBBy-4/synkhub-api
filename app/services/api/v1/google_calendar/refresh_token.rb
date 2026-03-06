# frozen_string_literal: true

module Api
  module V1
    module GoogleCalendar
      class RefreshToken < BaseService
        attr_reader :user

        TOKEN_URL = "https://oauth2.googleapis.com"

        def initialize(user:)
          @user = user
        end

        def call
          return fail!("Google Calendar is not connected") unless user.google_calendar_connected?
          return success(user) unless user.google_token_expired?

          token_data = refresh_access_token
          return fail!("Failed to refresh access token") unless token_data["access_token"]

          user.update!(
            google_access_token: token_data["access_token"],
            google_token_expires_at: Time.current + token_data["expires_in"].to_i.seconds
          )

          success(user)
        end

        private

        attr_writer :user

        def refresh_access_token
          response = token_connection.post("/token", {
                                             grant_type: "refresh_token",
                                             client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
                                             client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
                                             refresh_token: user.google_refresh_token,
                                           })

          response.body
        end

        def token_connection
          Faraday.new(url: TOKEN_URL) do |f|
            f.request :url_encoded
            f.response :json
            f.headers["User-Agent"] = "SynkHub"
          end
        end
      end
    end
  end
end
