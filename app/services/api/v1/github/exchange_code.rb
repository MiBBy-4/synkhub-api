# frozen_string_literal: true

module Api
  module V1
    module Github
      class ExchangeCode < BaseService
        attr_reader :user, :code, :state

        GITHUB_OAUTH_URL = "https://github.com"
        GITHUB_API_URL = "https://api.github.com"

        def initialize(user:, code:, state:)
          @user = user
          @code = code
          @state = state
        end

        def call
          return fail!("Invalid state parameter") unless valid_state?

          token_data = exchange_token
          return fail!("Failed to obtain access token") unless token_data["access_token"]

          github_user = fetch_github_user(token_data["access_token"])
          return fail!("Failed to fetch GitHub user") unless github_user["id"]

          user.assign_attributes(
            github_uid: github_user["id"].to_s,
            github_username: github_user["login"],
            github_access_token: token_data["access_token"],
            github_token_scope: token_data["scope"]
          )

          return fail!("GitHub account is already linked to another user") unless user.save

          success(user)
        end

        private

        attr_writer :user, :code, :state

        def valid_state?
          return false unless state.is_a?(String) && state.match?(/\A[0-9a-f]{64}\z/)

          cache_key = "github_oauth_state:#{user.id}"
          cached_state = Rails.cache.read(cache_key)
          return false unless cached_state

          valid = ActiveSupport::SecurityUtils.secure_compare(cached_state, state)
          Rails.cache.delete(cache_key) if valid
          valid
        end

        def exchange_token
          response = oauth_connection.post("/login/oauth/access_token", {
                                             client_id: ENV.fetch("GITHUB_CLIENT_ID"),
                                             client_secret: ENV.fetch("GITHUB_CLIENT_SECRET"),
                                             code: code,
                                             redirect_uri: ENV.fetch("GITHUB_REDIRECT_URI"),
                                           })

          response.body
        end

        def fetch_github_user(access_token)
          response = api_connection(access_token).get("/user")

          response.body
        end

        def oauth_connection
          Faraday.new(url: GITHUB_OAUTH_URL) do |f|
            f.request :json
            f.response :json
            f.headers["Accept"] = "application/json"
            f.headers["User-Agent"] = "SynkHub"
          end
        end

        def api_connection(access_token)
          Faraday.new(url: GITHUB_API_URL) do |f|
            f.request :json
            f.response :json
            f.headers["Authorization"] = "Bearer #{access_token}"
            f.headers["User-Agent"] = "SynkHub"
          end
        end
      end
    end
  end
end
