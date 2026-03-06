# frozen_string_literal: true

module Api
  module V1
    module GoogleCalendar
      class ExchangeCode < BaseService
        attr_reader :user, :code, :state

        TOKEN_URL = "https://oauth2.googleapis.com"
        USERINFO_URL = "https://www.googleapis.com"

        def initialize(user:, code:, state:)
          @user = user
          @code = code
          @state = state
        end

        def call
          cache_key = "google_oauth_state:#{user.id}"
          Rails.logger.info("[GoogleCalendar] State param: #{state.inspect}, cached: #{Rails.cache.read(cache_key).inspect}")
          return fail!("Invalid state parameter") unless valid_state?

          token_data = exchange_token
          Rails.logger.info("[GoogleCalendar] Token response: #{token_data.inspect}")
          return fail!("Failed to obtain access token") unless token_data["access_token"]
          return fail!("No refresh token received") unless token_data["refresh_token"]

          userinfo = fetch_userinfo(token_data["access_token"])
          Rails.logger.info("[GoogleCalendar] Userinfo response: #{userinfo.inspect}")
          return fail!("Failed to fetch Google user info") unless userinfo["sub"]

          user.assign_attributes(
            google_uid: userinfo["sub"],
            google_email: userinfo["email"],
            google_access_token: token_data["access_token"],
            google_refresh_token: token_data["refresh_token"],
            google_token_expires_at: Time.current + token_data["expires_in"].to_i.seconds,
            google_token_scope: token_data["scope"]
          )

          return fail!("Google account is already linked to another user") unless user.save

          success(user)
        end

        private

        attr_writer :user, :code, :state

        def valid_state?
          return false unless state.is_a?(String) && state.match?(/\A[0-9a-f]{64}\z/)

          cache_key = "google_oauth_state:#{user.id}"
          cached_state = Rails.cache.read(cache_key)
          return false unless cached_state

          valid = ActiveSupport::SecurityUtils.secure_compare(cached_state, state)
          Rails.cache.delete(cache_key) if valid
          valid
        end

        def exchange_token
          response = token_connection.post("/token", {
                                             code: code,
                                             client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
                                             client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
                                             redirect_uri: ENV.fetch("GOOGLE_REDIRECT_URI"),
                                             grant_type: "authorization_code",
                                           })

          response.body
        end

        def fetch_userinfo(access_token)
          response = api_connection(access_token).get("/oauth2/v3/userinfo")

          response.body
        end

        def token_connection
          Faraday.new(url: TOKEN_URL) do |f|
            f.request :url_encoded
            f.response :json
            f.headers["User-Agent"] = "SynkHub"
          end
        end

        def api_connection(access_token)
          Faraday.new(url: USERINFO_URL) do |f|
            f.response :json
            f.headers["Authorization"] = "Bearer #{access_token}"
            f.headers["Accept"] = "application/json"
            f.headers["User-Agent"] = "SynkHub"
          end
        end
      end
    end
  end
end
