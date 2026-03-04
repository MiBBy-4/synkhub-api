# frozen_string_literal: true

module Api
  module V1
    module Github
      class GenerateAuthUrl < BaseService
        attr_reader :user

        SCOPES = [
          REPO_SCOPE = "repo",
          READ_USER_SCOPE = "read:user",
          USER_EMAIL_SCOPE = "user:email",
          NOTIFICATIONS_SCOPE = "notifications",
          ADMIN_REPO_HOOK_SCOPE = "admin:repo_hook",
        ].freeze

        def initialize(user:)
          @user = user
        end

        def call
          state = SecureRandom.hex(32)
          Rails.cache.write(cache_key, state, expires_in: 10.minutes)

          params = {
            client_id: ENV.fetch("GITHUB_CLIENT_ID"),
            redirect_uri: ENV.fetch("GITHUB_REDIRECT_URI"),
            scope: SCOPES.join(" "),
            state: state,
          }

          url = "https://github.com/login/oauth/authorize?#{params.to_query}"

          success(url)
        end

        private

        attr_writer :user

        def cache_key
          "github_oauth_state:#{user.id}"
        end
      end
    end
  end
end
